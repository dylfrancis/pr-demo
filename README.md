# pr-demo

A [Claude Code](https://claude.com/claude-code) skill that records a short video demo of a pull request's UI change
with [agent-browser](https://github.com/vercel-labs/agent-browser), ready to drag into the PR description.

Run `/pr-demo 123` and Claude reads the PR's diff, picks the flow that shows the change, rehearses it in a headless
browser, then records it in one scripted take with a gliding pointer and visible typing. It checks the footage
against a contact sheet of key frames and saves the video to `~/Desktop/<repo>-pr-123-demo.mp4`. Drop that file into
the PR description and GitHub shows it as an inline player.

## Requirements

- [Claude Code](https://claude.com/claude-code)
- agent-browser: `npm i -g agent-browser && agent-browser install`
- ffmpeg, with the libx264 encoder: `brew install ffmpeg` (macOS) or `sudo apt install ffmpeg` (Debian/Ubuntu)
- [GitHub CLI](https://cli.github.com), signed in: `gh auth login`
- `jq`

Run `agent-browser doctor` to check that recording works.

## Install

Clone it into your personal skills folder:

```bash
git clone https://github.com/dylfrancis/pr-demo.git ~/.claude/skills/pr-demo
```

The skill expects this exact path, because its take scripts source `~/.claude/skills/pr-demo/scripts/take-lib.sh`.

## Usage

From the repo the PR belongs to, with the PR's branch checked out and the app running locally:

```text
/pr-demo                          # the current branch's PR
/pr-demo 123                      # a specific PR
/pr-demo 123 show the empty state # tell it what to show
```

The skill only runs when you invoke it. It never uploads the video or edits the PR.

## How it works

- `SKILL.md` holds the instructions Claude follows: preflight, planning, rehearsal, the take, the footage check.
- `scripts/take-lib.sh` is sourced by each take. It provides `glide` (move the pointer on an eased curve, then click),
  `slowtype` (type one key at a time) and stops the recording if a step fails.
