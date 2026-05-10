# Getting Started — Two-Person GitHub Workflow with Claude

A no-prior-experience guide to using GitHub so you and your friend can both work on JARVIS at the same time using your own Claude accounts.

## The mental model

GitHub is a website that hosts a folder of code in the cloud. You each "clone" that folder onto your own computer. Claude edits files in your local folder. You "push" your changes back to GitHub when ready. Your friend "pulls" them down. **Branches** let each person work on a different feature in isolation, then **merge** them together when ready.

That's the whole thing. Everything else is just menu clicks.

---

## Step 1 — GitHub accounts

Both of you go to **https://github.com** and sign up (free). Pick a username you can live with for years.

## Step 2 — Install GitHub Desktop

Skip the command line entirely. Download **GitHub Desktop** from https://desktop.github.com — it's a free app with buttons for everything you'll ever need: clone, pull, commit, push, branch, merge.

Both of you install it and sign in with your GitHub account.

## Step 3 — The repo (already done!)

The repo lives at **https://github.com/JustAStickmin/Jarvis-CC**. If you're the friend reading this for the first time, ask Willie to add you as a collaborator: **Settings → Collaborators → Add people**.

## Step 4 — Both of you clone the repo

In GitHub Desktop:
- **File → Clone repository**
- Pick `Jarvis-CC` from the list (or paste the URL)
- Choose where to put it (`Documents/GitHub/` is the default and totally fine)
- Click **Clone**

You now have a local folder linked to GitHub.

## Step 5 — Connect Claude to the cloned folder

In Cowork, when starting a session, choose to **select a folder** and pick your `Jarvis-CC` folder. Now Claude can read, write, and edit files directly inside the repo on your computer.

If you don't see the folder picker, just say "work in my Jarvis-CC folder" and Claude will prompt you.

Your friend does the same on their own machine with their own Claude account.

## Step 6 — Daily working rhythm

Every time you sit down to work:

### Before you start
1. Open GitHub Desktop
2. Click **Fetch origin** then **Pull origin** (gets your friend's latest changes)

### Make a branch for your work
3. **Current Branch** dropdown (top middle) → **New Branch**
4. Name it like `willie/defense-system` (yourname/feature)
5. Click **Create Branch**

This isolates your work so you don't conflict with your friend.

### Do the work
6. Tell Claude what you want to build. It edits files in the folder.

### Save and share
7. In GitHub Desktop you'll see all the changes listed in the left panel
8. Bottom-left: type a short summary like "added defense system commands"
9. Click **Commit to willie/defense-system**
10. Click **Push origin** (top-right area)

### Get it merged into main
11. Go to the repo on github.com — there'll be a yellow banner: **Compare & pull request**
12. Click it, then **Create pull request**
13. Your friend reviews it and clicks **Merge pull request**
14. Now their next pull will pull in your changes

## Step 7 — Handling merge conflicts

Sometimes you both edit the same line and git can't auto-merge. GitHub Desktop will highlight the conflicted file. Open it, you'll see:

```
<<<<<<< HEAD
your version
=======
your friend's version
>>>>>>> main
```

Pick one (or combine them), delete the `<<<` `===` `>>>` markers, save, and commit. Done.

This is rarer when the JARVIS code is split into multiple files (one of the next things to do) because you'll naturally edit different files.

## Step 8 — In-game updater

Run this **once** in-game on your CC computer:

```
wget run https://raw.githubusercontent.com/JustAStickmin/Jarvis-CC/main/update.lua
```

After that, just run `update` whenever you want the latest code from GitHub. The updater pulls every file listed in the script, so as the project grows we'll add filenames to it.

To launch JARVIS after updating: `main`

---

## Quick reference card

| Want to | GitHub Desktop action |
|---|---|
| Get latest code | Fetch origin → Pull origin |
| Start new feature | Current Branch → New Branch |
| Save your work locally | Type message, Commit to (branch) |
| Share your work | Push origin |
| Get it into main | Push, then Compare & pull request on github.com |
| Switch what you're working on | Current Branch → pick a branch |

## Rules of thumb

- **Pull before you start working**, every time.
- **Never commit directly to `main`** — always make a branch, even for small changes.
- **Commit often** with short clear messages. Small commits are easier to undo if something breaks.
- **Push when you take a break** so your work is backed up to GitHub even if your computer dies.
- **One feature per branch.** Don't mix the defense system and the train dispatcher in the same branch.

## When things break

- **"I committed to the wrong branch"** → GitHub Desktop has **History → right-click commit → Revert** or **Move to another branch**.
- **"I have changes I don't want to lose but need to switch branches"** → **Branch → Stash changes**.
- **"I broke main"** → don't panic. Make a new branch from a known-good commit and PR it. Main is recoverable.
- **"Merge conflict scares me"** → ping each other before editing the same file. Conflicts are inconvenient, not dangerous.
