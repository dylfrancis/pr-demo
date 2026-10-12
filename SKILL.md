---
name: pr-demo
description: Record a short video demo of a pull request's UI change with agent-browser and save it to the Desktop, for the user to drag into the PR description. Use when asked to record, film or demo a PR, or to add a video to a pull request.
compatibility: Needs bash, agent-browser with ffmpeg (libx264), the GitHub CLI (gh) and jq.
allowed-tools: Bash(agent-browser *) Bash(gh pr view *) Bash(gh pr diff *) Bash(gh repo view *) Bash(ffprobe *) Bash(cp *)
---

Record a video of the change in a PR and save it to the Desktop as an .mp4. The user drags it into the PR
description, where GitHub turns it into an inline player; GitHub has no API for PR attachments, so never upload it or
edit the PR. Make it only as long as the change needs, and keep it under 60 seconds.
Load `agent-browser skills get core` before the first `agent-browser` command.

`scripts/take-lib.sh`, in this skill's folder, is sourced by the take script; it defines `ab`, `glide`, `slowtype`, and
stops the recording if a step fails.

## 1. Preflight

- `agent-browser doctor` must pass "Recording". If it does not, stop and tell the user to run `brew install ffmpeg`.
- Resolve the PR the user named, by number or URL: `gh pr view <pr> --json number,url,title,body,headRefName`. If they
  named none, omit `<pr>` to get the current branch's PR. Anything else in the request says what to show.
- The checked-out branch must be the PR's `headRefName`, and the app must be running from it. Find the local URL from
  the project's run skill, README or `package.json` scripts, and start the dev server if it is not up.
- Set up paths and an isolated browser session:
  ```bash
  OUT="${TMPDIR:-/tmp}/pr-demo/<number>"; mkdir -p "$OUT"   # never inside the repo
  cp "<skill folder>/scripts/take-lib.sh" "$OUT/"          # <skill folder> holds this SKILL.md
  SESSION="$(agent-browser session id --scope worktree --prefix pr-demo)"
  ```

## 2. Plan the demo

Read `gh pr diff <number>` and the PR body. Pick the one user-visible flow that shows the change, in 3–6 beats:
the starting state, each action, and the result held on screen. If the user named what to show, follow that. If the
change has no UI, say so and stop.

## 3. Rehearse without recording

```bash
agent-browser --session "$SESSION" open <url>
agent-browser --session "$SESSION" set viewport 1280 800
agent-browser --session "$SESSION" snapshot -i
```

Walk the flow once with snapshots. Clear anything that would clutter the take: a login screen, empty data, dev
overlays such as the Next.js indicator or query devtools. Note the role and name of everything the take clicks, as
the snapshot shows them (`button "Save profile"`), because `@eN` refs do not survive the reload before the real take.

## 4. Record the take as one script

Time spent deciding between commands shows up as dead air in the video, so the whole take runs as one script with
deliberate pauses. Write `$OUT/take.sh`, then run `SESSION="$SESSION" OUT="$OUT" bash "$OUT/take.sh"`:

```bash
#!/usr/bin/env bash
source "${OUT:?}/take-lib.sh"

ab open "<start url>"
ab set viewport 1280 800
ab wait --load networkidle
ab mouse move 640 400                          # the pointer's first glide starts from here
ab record start "$OUT/demo.mp4" --cursor --contact-sheet-threshold 0.01
ab wait 1200                                   # hold on the starting state
glide button "New project"
ab wait 600
glide textbox "Name"
slowtype "Launch plan"                         # visible typing; use `ab fill` for long text
ab wait 400
glide button "Create"
ab wait --text "Launch plan"
ab wait 1800                                   # hold on the result
ab record stop --json > "$OUT/record.json"
```

Click with `glide <role> "<name>" [ms]`, which moves the pointer to the element on an eased curve over 700 ms
(or `ms`) and clicks it. `find ... click` and `--input-mode smooth` move it within a frame, so it looks like a jump.

Keep `.mp4`: H.264 plays everywhere, including Safari. Keep the default 30 fps unless the change is an animation.

## 5. Check the footage

- Look at the image at `.data.contactSheetPath` in `$OUT/record.json`. It must show the change itself, not a login
  screen, an error overlay, a spinner or a blank page. If it does not, fix the cause and run `take.sh` again.
- `ffprobe -v error -show_entries format=duration,size -of csv=p=0 "$OUT/demo.mp4"`. GitHub rejects videos over
  10 MB on free plans. If it is larger, shrink it and use the smaller file from here on:
  `ffmpeg -y -i "$OUT/demo.mp4" -c:v libx264 -crf 30 -preset slow -vf scale=1280:-2 -an "$OUT/demo-small.mp4"`

## 6. Save the video to the Desktop

```bash
cp "$OUT/demo.mp4" ~/Desktop/<repo>-pr-<number>-demo.mp4   # the smaller file, if step 5 made one
```

`<repo>` is `gh repo view --json name -q .name`. A later take of the same PR replaces the file.

## 7. Finish

Run `agent-browser --session "$SESSION" close`. Report the video's Desktop path, duration and size, the contact sheet
path and the PR URL, and tell the user to drag the video into the PR description.
