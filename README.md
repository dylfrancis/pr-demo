# pr-demo

An [Agent Skill](https://agentskills.io) that records a short video demo of a pull request's UI change with
[agent-browser](https://github.com/vercel-labs/agent-browser), ready to drag into the PR description. It works in any
agent that supports Agent Skills, such as Claude Code, Codex, Cursor, OpenCode, GitHub Copilot and Gemini CLI.

Ask your agent to demo a PR, and it reads the PR's diff, picks the flow that shows the change, rehearses it in a
headless browser, then records it in one scripted take with a gliding pointer and visible typing. It checks the
footage against a contact sheet of key frames and saves the video to `~/Desktop/<repo>-pr-<number>-demo.mp4`. Drop
that file into the PR description and GitHub shows it as an inline player.

## Requirements

- An agent that supports [Agent Skills](https://agentskills.io) and can view images
- agent-browser: `npm i -g agent-browser && agent-browser install`
- ffmpeg, with the libx264 encoder: `brew install ffmpeg` (macOS) or `sudo apt install ffmpeg` (Debian/Ubuntu)
- [GitHub CLI](https://cli.github.com), signed in: `gh auth login`
- `bash` and `jq`

Run `agent-browser doctor` to check that recording works.

## Install

With the [skills CLI](https://github.com/vercel-labs/skills), which asks which agents to install it for:

```bash
npx skills add dylfrancis/pr-demo -g
```

Or clone it into your agent's skills folder, for example:

```bash
git clone https://github.com/dylfrancis/pr-demo.git ~/.agents/skills/pr-demo   # Codex
git clone https://github.com/dylfrancis/pr-demo.git ~/.claude/skills/pr-demo   # Claude Code
```

## Usage

From the repo the PR belongs to, with the PR's branch checked out and the app running locally, ask for it:

```text
record a demo of PR 123
demo this branch's PR, and show the empty state
```

Agents that expose skills as commands can also run it directly, like `/pr-demo 123` in Claude Code.

The skill never uploads the video or edits the PR.

## How it works

- `SKILL.md` holds the instructions the agent follows: preflight, planning, rehearsal, the take, the footage check.
- `scripts/take-lib.sh` is sourced by each take. It provides `glide` (move the pointer on an eased curve, then click),
  `slowtype` (type one key at a time) and stops the recording if a step fails.
