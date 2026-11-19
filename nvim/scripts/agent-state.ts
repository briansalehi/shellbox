// opencode plugin for the observer and the mentor: the opencode counterpart of
// claude's hooks. lua/plugins/agents.lua loads it through OPENCODE_CONFIG_CONTENT
// for those two agents only, so other opencode sessions never see it.
//
// It reports each state change through agent-state.lua, which forwards it to the
// nvim that owns the terminal, using the same events as claude's hooks: 'start',
// 'busy', 'stop' with the last reply, and 'compact'. It never throws, so it cannot
// break the session it runs in.

import { dirname, join } from "node:path"
import { fileURLToPath } from "node:url"

const script = join(dirname(fileURLToPath(import.meta.url)), "agent-state.lua")

function report(event: string, message?: string) {
    try {
        const proc = Bun.spawn(["nvim", "--clean", "-l", script, event], {
            stdin: "pipe",
            stdout: "ignore",
            stderr: "ignore",
        })
        proc.stdin.write(JSON.stringify({ last_assistant_message: message ?? null }))
        proc.stdin.end()
    } catch {}
}

async function lastReply(client: any, id: string): Promise<string | undefined> {
    try {
        const res = await client.session.messages({ path: { id } })
        const messages: any[] = res.data ?? []
        for (let i = messages.length - 1; i >= 0; i--) {
            const { info, parts } = messages[i]
            if (info.role !== "assistant") continue
            return parts
                .filter((p: any) => p.type === "text" && !p.synthetic)
                .map((p: any) => p.text)
                .join("\n")
        }
    } catch {}
    return undefined
}

export const AgentState = async ({ client }: any) => {
    if (!(process.env.NVIM && process.env.AGENT_NAME && process.env.AGENT_ROOT)) return {}
    // claude reports a fresh start the same way; without it nvim waits for a first turn
    report("start")
    const children = new Set<string>()
    return {
        event: async ({ event }: any) => {
            const p = event.properties ?? {}
            switch (event.type) {
                case "session.created":
                    // a subagent's session is not the one nvim types into
                    if (p.info?.parentID) children.add(p.info.id)
                    else report("start")
                    break
                case "session.status":
                    if (!children.has(p.sessionID) && p.status?.type === "busy") report("busy")
                    break
                case "session.idle":
                    // an interrupted turn goes idle too, unlike claude's Stop
                    if (!children.has(p.sessionID)) report("stop", await lastReply(client, p.sessionID))
                    break
                case "session.compacted":
                    if (!children.has(p.sessionID)) report("compact")
                    break
            }
        },
    }
}
