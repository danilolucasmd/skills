---
name: dotfiles-port
description: Port dotfiles changes from one branch of the user's dotfiles repo (~/dotfiles) to another, usually between the macOS and Linux branches. Use when the user says "port my dotfiles changes", "copy my dotfiles changes to the other branch", "bring my nvim changes over to arch", "sync my config to macos", or asks to move, copy, migrate, or carry over config changes (nvim, lazyvim, git, zsh, herdr, lazygit, yazi, ghostty, claude) between dotfiles branches or machines.
---

# Porting dotfiles changes between branches

The repo lives at `~/dotfiles` on every machine. Each branch is one machine's setup (one for macOS, others for Linux flavors), laid out as stow packages: one top-level directory per tool. The branches diverged long ago and do not share recent history, so never merge, rebase, or copy whole trees between them. Port individual changes.

Invoking this skill authorizes `git fetch`, `git worktree add`, and the read-only commands below. It does not authorize staging, committing, or pushing.

## 1. Pick the branches

1. Run `git -C ~/dotfiles fetch --prune origin`.
2. List local and remote branches and ask in one multiple-choice question call (`AskUserQuestion` in Claude Code):
   - **Source:** default (first option, marked Recommended) is the currently checked-out branch; offer the others too.
   - **Target:** the remaining branches, the one for the other OS first.
3. Ask how far back to look: since the last port (default), the last week, the last month, or a specific commit. "Since the last port" means since the newest source commit whose subject also appears in the target's log; if there is none, fall back to the last two weeks and say so.

Compare against `origin/<branch>` when the local branch is behind it, and tell the user which ref you used.

## 2. Collect candidate changes

- Commits: `git log --no-merges --cherry-pick --right-only --reverse <target>...<source>` limited to the chosen window. Drop any commit whose subject already appears in the target's log, since earlier ports were done by hand and have different patch IDs.
- Uncommitted work: if the source is the branch checked out in `~/dotfiles`, include `git status` and `git diff HEAD` as one extra candidate.

For each candidate, read the actual diff, not just the subject.

## 3. Filter to what is portable

Split every candidate by stow package and keep only portable hunks.

- **Portable:** tools that run on both OSes, such as `nvim`, `git`, `lazygit`, `zsh`, `herdr`, `claude`, `yazi`, `tmux`, `btop`, `ghostty`.
- **Not portable, skip silently:** packages for one OS's window manager, input remapping, bar, or system services (on macOS things like `aerospace`, `skhd`, `yabai`, `karabiner`, `linearmouse`; on Linux things like `hypr`, `waybar`, `kanata`, `quickshell`, `sddm`, `dbus`, `wireplumber`). Also skip the root `install.sh`, which is a per-OS package bootstrap. Judge unlisted packages by the same test: does the tool exist on the target OS?
- **Mixed files:** inside a portable file, skip hunks that only make sense on the source OS: Homebrew or `/opt/homebrew` paths, `pbcopy`/`wl-copy`, `osxkeychain`/`libsecret` credential helpers, `macos-*` or Wayland-only options, OS-specific keybinds such as Cmd versus Super. Do not translate them. Keep a list to report at the end.
- **Generated or noisy files:** `lazy-lock.json`, `*.bak`, release notes and similar state files. Offer them as a separate, unselected option rather than mixing them into a feature.

Drop candidates left with no portable hunks.

## 4. Ask what to port

Group the surviving changes by package, then by feature (one commit, or a few commits touching the same thing). Ask with a multi-select question, one question per package, each option a feature with a one-line description of the behavior it changes. When a package has more than four features, split it across questions or merge the smallest ones; when there are more than four packages, ask in several rounds.

## 5. Apply on the target

1. Find a checkout of the target: an existing worktree on that branch (`git worktree list`), else `git -C ~/dotfiles worktree add ~/.dotfiles-worktrees/<target> <target>`, creating a local tracking branch from `origin/<target>` when needed. If the target is the branch checked out in `~/dotfiles`, work there.
2. If the checkout has uncommitted changes, stop and ask before touching it.
3. For each selected change, try `git apply --3way` of just the portable hunks. When it does not apply cleanly, which is common because the files have drifted, read the target file and reimplement the change by hand so it does what it did on the source while fitting the target's surrounding code.
4. When a ported change depends on something the target lacks (a helper module, a plugin, a CLI tool), port that dependency too if it is portable, or flag it.
5. Syntax-check what you touched: `nvim --headless -c "lua assert(loadfile('<file>'))" -c qa` per Lua file, `zsh -n` for zsh files, `git config -f <file> --list` for git config.

## 6. Report and stop

Leave everything uncommitted. Report briefly:

- The checkout path and target branch.
- What was ported, by package.
- Hunks skipped as platform-specific, with file and a few words each, so the user can port them by hand if wanted.
- Anything reimplemented rather than applied cleanly, and any validation failures.

Suggest the source commit subjects as commit messages, since matching subjects is how the next run detects what was already ported.
