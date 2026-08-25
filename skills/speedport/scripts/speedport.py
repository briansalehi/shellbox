#!/usr/bin/env python3
"""Read-only client for a Telekom Speedport router's web UI.

The Speedport web UI does not expose an API. It talks to /data/<Page>.json with
both request and response bodies wrapped in AES-256-CCM, using a key that ships
in the router's own JavaScript. This reproduces exactly what a browser does, so
the router sees an ordinary UI session.

Read-only by design: it logs in and GETs pages. It never posts settings.

Usage:
    speedport.py pages                     # discover which data pages exist
    speedport.py get Status Overview       # dump pages as varid = value
    speedport.py devices                   # connected clients, one per line
    speedport.py json Status               # raw decrypted JSON

Password resolution, in order:
    --password / -p
    $SPEEDPORT_PASSWORD
    ~/.config/speedport/password  (first line)
"""

import argparse
import binascii
import hashlib
import http.cookiejar
import json
import os
import pathlib
import re
import sys
import urllib.parse
import urllib.request

try:
    from cryptography.hazmat.primitives.ciphers.aead import AESCCM
except ImportError:
    sys.exit("needs python3-cryptography (Fedora: sudo dnf install python3-cryptography)")

# Published in the router's own js/jquery-addons.js (function decryptccm). It is
# a fixed obfuscation key, not a secret -- the real auth is the challenge below.
DEFAULT_KEY = binascii.unhexlify(
    "cdc0cac1280b516e674f0057e4929bca84447cca8425007e33a88a5cf598a190"
)


def resolve_password(cli_value):
    if cli_value:
        return cli_value
    if os.environ.get("SPEEDPORT_PASSWORD"):
        return os.environ["SPEEDPORT_PASSWORD"]
    path = pathlib.Path.home() / ".config" / "speedport" / "password"
    if path.exists():
        return path.read_text().splitlines()[0].strip()
    sys.exit("no password: pass --password, set $SPEEDPORT_PASSWORD, "
             "or write ~/.config/speedport/password")


class Speedport:
    def __init__(self, host, password):
        self.base = f"http://{host}"
        self.password = password
        self.session_key = None
        jar = http.cookiejar.CookieJar()
        self.opener = urllib.request.build_opener(
            urllib.request.HTTPCookieProcessor(jar)
        )
        self.opener.addheaders = [
            ("User-Agent", "Mozilla/5.0 (X11; Linux x86_64) Gecko/20100101 Firefox/154.0"),
            ("Referer", f"{self.base}/html/login/login.html?lang=en"),
        ]

    # --- crypto -----------------------------------------------------------
    # sjcl CCM with a 8-byte nonce taken from the head of the key and a
    # 128-bit tag appended to the ciphertext.

    @staticmethod
    def _encrypt(params, key):
        body = urllib.parse.urlencode(params).encode()
        ct = AESCCM(key, tag_length=16).encrypt(key[:8], body, b"")
        return binascii.hexlify(ct)

    def _decrypt(self, raw):
        raw = raw.strip()
        if raw[:1] in (b"[", b"{"):
            return json.loads(raw)  # some pages come back in the clear
        ct = binascii.unhexlify(raw)
        # session key first, default key as fallback: the router is
        # inconsistent about which one it uses per endpoint.
        for key in filter(None, (self.session_key, DEFAULT_KEY)):
            try:
                return json.loads(AESCCM(key, tag_length=16).decrypt(key[:8], ct, b""))
            except Exception:
                continue
        raise ValueError("could not decrypt response with either key")

    # --- transport --------------------------------------------------------

    def _post_login(self, params, key=DEFAULT_KEY):
        req = urllib.request.Request(
            f"{self.base}/data/Login.json",
            data=self._encrypt(params, key),
            headers={"Content-Type": "application/x-www-form-urlencoded"},
        )
        return self._decrypt(self.opener.open(req, timeout=20).read())

    def _open(self, path, referer=None):
        headers = {"X-Requested-With": "XMLHttpRequest"}
        if referer:
            headers["Referer"] = self.base + referer
        req = urllib.request.Request(self.base + path, headers=headers)
        return self.opener.open(req, timeout=20).read()

    # --- api --------------------------------------------------------------

    def login(self):
        challenge = var(self._post_login({"getChallenge": 1, "httoken": ""}), "challenge")
        if not challenge:
            sys.exit("router did not return a challenge")
        digest = hashlib.sha256(f"{challenge}:{self.password}".encode()).hexdigest()
        res = self._post_login({
            "csrf_token": "nulltoken",
            "showpw": 0,
            "password": digest,
            "challenge": challenge,
            "httoken": "",
        })
        if var(res, "login") != "success":
            locked = var(res, "login_locked")
            sys.exit(f"login failed{f' (locked {locked}s)' if locked else ''}")
        # from here on responses are keyed on the challenge itself
        self.session_key = binascii.unhexlify(challenge)
        return self

    def page(self, name, referer=None):
        """Fetch /data/<name>.json. Some pages only answer with their owning
        HTML page's Referer, so pass it when a bare fetch comes back empty."""
        if referer:
            self._open(referer)  # establish page context
        return self._decrypt(self._open(f"/data/{name}.json?lang=en", referer))

    def discover(self):
        """Walk the UI navigation and report every /data source it references."""
        found, seen, queue = {}, set(), ["/html/content/overview/index.html?lang=en"]
        while queue:
            path = queue.pop(0)
            if path in seen:
                continue
            seen.add(path)
            try:
                html = self._open(path).decode("utf8", "replace")
            except Exception:
                continue
            for src in re.findall(r"JSONSource\s*=\s*'([^']+)'", html):
                found.setdefault(src.split("/")[-1].removesuffix(".json"), path)
            for href in re.findall(r'href="(\.\./[^"]+\.html[^"]*)"', html):
                nxt = urllib.parse.urljoin(self.base + path, href).replace(self.base, "")
                if nxt.startswith("/html/content/"):
                    queue.append(nxt)
        return found


def var(doc, name):
    """Speedport JSON is a flat list of {varid, varvalue} records."""
    return next((e.get("varvalue") for e in doc if e.get("varid") == name), None)


def flatten(entry):
    """A varvalue is sometimes itself a list of records (device rows, etc)."""
    value = entry.get("varvalue")
    if isinstance(value, list):
        return ", ".join(f"{i.get('varid')}={i.get('varvalue')}" for i in value)
    return value


# Pages worth knowing about. Anything else shows up via `pages`.
KNOWN_REFERERS = {
    "DeviceList": "/html/content/network/devices.html?lang=en",
}


def main():
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("command", choices=["pages", "get", "devices", "json"])
    ap.add_argument("args", nargs="*")
    ap.add_argument("-p", "--password")
    ap.add_argument("--host", default="speedport.ip")
    opts = ap.parse_args()

    sp = Speedport(opts.host, resolve_password(opts.password)).login()

    if opts.command == "pages":
        for name, page in sorted(sp.discover().items()):
            print(f"{name:24s} {page}")
        return

    if opts.command == "devices":
        doc = sp.page("DeviceList", KNOWN_REFERERS["DeviceList"])
        for entry in doc:
            # each client is a "template" record (varid addmdevice) whose
            # varvalue is itself a list of mdevice_* fields
            if not isinstance(entry.get("varvalue"), list):
                continue
            row = dict(
                (i.get("varid", "").removeprefix("mdevice_"), i.get("varvalue"))
                for i in entry["varvalue"]
            )
            if "name" not in row:
                continue
            speed = int(row.get("downspeed") or 0) // 1_000_000
            print(f"{row.get('name', ''):28s} "
                  f"{'up  ' if row.get('connected') == '1' else 'down'} "
                  f"{row.get('ipv4', ''):16s} "
                  f"rssi={str(row.get('rssi', '')):5s} "
                  f"{str(row.get('standards', '')):26s} {speed}M")
        return

    if not opts.args:
        sys.exit(f"{opts.command}: name a page (try `pages`)")

    for name in opts.args:
        doc = sp.page(name, KNOWN_REFERERS.get(name))
        if opts.command == "json":
            print(json.dumps(doc, indent=2))
        else:
            print(f"===== {name} =====")
            for entry in doc:
                print(f"  {entry.get('varid')} = {flatten(entry)}")


if __name__ == "__main__":
    main()
