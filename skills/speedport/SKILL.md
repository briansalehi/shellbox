---
name: speedport
description: Read configuration and diagnostics from a Telekom Speedport router (Smart 3/4 family) over its web UI - WiFi channels and SSIDs, DSL sync rate, connected clients and their link rates. Use when investigating home network problems, slow or unstable WiFi, streaming or cloud-gaming stutter, or when asked what is connected to the router. Also covers the local-side WiFi measurements (airtime utilisation, per-hop latency) that tell you whether a problem is the internet line or the wireless link.
---

# Speedport router

The Speedport web UI has no API. Its pages fetch `/data/<Page>.json`, with both
request and response bodies wrapped in AES-256-CCM using a key that ships in the
router's own JavaScript. `scripts/speedport.py` reproduces that exchange, so the
router sees an ordinary UI session.

**It is read-only.** It logs in and reads. It never writes settings — see
"Changing settings" below.

## Setup

This lives in the shellbox dotfiles repo under `skills/`. Deploy it with
`make speedport` from the repo root, which symlinks it into `~/.claude/skills/`
— after that, edits here are live.

Needs `python3-cryptography` (Fedora: `sudo dnf install python3-cryptography`).

The password is the router's device password, printed on the sticker on the
underside. Resolution order:

1. `--password`
2. `$SPEEDPORT_PASSWORD`
3. `~/.config/speedport/password` (first line)

Prefer the file. Create it `chmod 600` and never paste the password into a
command line that lands in shell history or a transcript.

## Commands

```bash
S=~/.claude/skills/speedport/scripts/speedport.py

python3 $S pages                    # discover every /data page the UI uses
python3 $S get Status               # dump a page as "varid = value"
python3 $S get Status Overview      # several at once
python3 $S json DeviceList          # raw decrypted JSON
python3 $S devices                  # connected clients, one per line
python3 $S --host 192.168.2.1 ...   # if speedport.ip does not resolve
```

`Status` is the one to reach for first — it carries DSL sync rate, both SSIDs,
both channels, and uptime.

## Fields worth knowing

From `get Status`:

| field | meaning |
|---|---|
| `dsl_downstream` / `dsl_upstream` | line sync rate in bit/s |
| `inet_download` / `inet_upload` | usable throughput after overhead |
| `dsl_link_status`, `onlinestatus` | `online` when the line is up |
| `inet_uptime`, `time_online` | last resync — a recent one means the line dropped |
| `wlan_ssid`, `wlan_channel` | 2.4 GHz |
| `wlan_5ghz_ssid`, `wlan_5ghz_channel` | 5 GHz |
| `*_channel_act` | channel actually in use, which differs from the configured one after a DFS event |
| `firmware_version`, `serial_number` | for support calls |

From `devices`, per client: name, up/down, IP, RSSI in dBm, negotiated standard
and width, and link rate. `11G` at 54M means a legacy 2.4 GHz client — those
force protection mode and cost the whole band disproportionate airtime.

The device list does **not** say which band a client is on. Infer it: `11AC` and
`11AX` at 40 MHz or wider is 5 GHz; `11G` is always 2.4 GHz; `11N` is ambiguous.
To be certain, check the client's own network screen.

## Diagnosing "the internet is bad"

The router's numbers alone will not tell you whether a problem is the line or
the wireless link. Measure both, from a machine on the same WiFi.

**Is the line healthy?** `dsl_downstream` for sync rate, and `inet_uptime` for
whether it has been resyncing.

**Is the wireless hop adding latency?** Ping the router itself — no internet
involved, so everything you see is one WiFi hop:

```bash
ping -c 200 -i 0.05 192.168.2.1 | grep 'time=' | sed 's/.*time=//;s/ ms//' \
  | awk '{a[NR]=$1;s+=$1} END{n=asort(a);
      printf "min=%s p50=%s p90=%s p99=%s max=%s avg=%.1f\n",
      a[1],a[int(n*.5)],a[int(n*.9)],a[int(n*.99)],a[n],s/n}'
```

A healthy hop is a low single-digit `p50` with `p99` under ~20 ms. A `p99` in
the hundreds is a saturated or interfered channel, and it will show up in games
and video calls as dropouts rather than as slowness.

**How congested is each channel?** Airtime utilisation, not signal strength, is
what decides this. A client at −55 dBm on an 85%-busy channel performs far worse
than one at −70 dBm on an idle one:

```bash
iw dev <iface> survey dump | awk '
  /frequency/{f=$2} /channel active time/{a=$4}
  /channel busy time/{b=$4; if(a>0) printf "%s MHz util=%5.1f%%\n", f, b*100/a}'
```

Above ~40% busy is congested; above ~70% expect stalls. Only the band the
interface is currently on gets sampled continuously — the other band's figures
come from brief scan visits, so treat them as indicative.

**Which channels are DFS?** On a DFS channel the AP must vacate the moment it
believes it sees radar, dropping every client for up to a minute. That looks
exactly like an intermittent connection.

```bash
iw list | grep -E 'MHz \[' | grep 'radar detection'
```

In the EU, 5 GHz channels 52–140 are DFS; 36–48 and 149–165 are not. For
anything latency-sensitive, prefer a non-DFS channel.

**Is DNS steering you to a distant CDN edge?** Compare what different resolvers
return for the service, then ping each. Judge by *minimum* RTT — the average is
contaminated by local WiFi jitter.

```bash
dig +short <host> @192.168.2.1      # whatever the router forwards to
dig +short <host> @194.25.0.60      # Telekom
```

## Changing settings

Not supported here, and do not improvise it. Writes need the per-page `_httoken`
CSRF value plus a correctly encrypted form POST; getting it wrong can leave the
WiFi in a broken state. Make changes in the browser UI, then verify with
`get Status`.

Every WiFi change restarts the radios and drops every client in the building for
a minute or two, so agree on the timing first.

Two changes reliably worth making on this hardware:

- **Give the 5 GHz radio its own SSID.** Both bands ship with the same name, and
  while that is true you cannot pin a device to the good radio. The 5 GHz name
  field is separate in *Heimnetzwerk → WLAN-Name und Verschlüsselung*.
- **Keep 5 GHz off DFS channels.** Fix it to 36–48.

After a client reconnects to a renamed SSID it may appear as a **new device with
a new MAC and IP** — phones and TVs randomise MAC per SSID. Any DHCP reservation
tied to the old MAC no longer applies.

## Notes

- Hostname is `speedport.ip`; the LAN address is typically `192.168.2.1`.
- Sessions expire after a few minutes idle, and logging in elsewhere invalidates
  an existing browser session. The script logs in fresh on every run, so running
  it will log the user out of the router's web UI.
- Repeated failed logins lock the router out for a while (`login_locked`).
- Some pages (`DeviceList`) only answer when their owning HTML page has been
  fetched first and is sent as `Referer`; `KNOWN_REFERERS` in the script handles
  the ones that need it. If a page returns empty, that is the likely cause.
- Responses use one of two keys — the session key derived from the login
  challenge, or the fixed key from the router's JS. The script tries both.
