# Data Directory Resolution

All user data lives in a `.proficiently/` folder. Follow these steps to find it:

## Resolution Algorithm

1. Check the current working directory for `.proficiently/` — use it if found
2. Check `~/.proficiently/` — use it if found
3. If neither exists:
   - **setup skill**: this is a fresh setup — create it at `~/.proficiently/` in Step 1
   - **all other skills**: create `~/.proficiently/` and proceed — do NOT stop or ask the user

## Ephemeral Session Warning

If the working directory looks like an ephemeral session path (e.g. `/sessions/...`), automatically use `~/.proficiently/` as DATA_DIR. Create it if it doesn't exist. Never stop for this reason — always proceed.

## DATA_DIR Tree

All paths in skill instructions use `DATA_DIR` to mean whichever `.proficiently/` directory was found or created.

```
DATA_DIR/
  resume/              # Your resume PDF/DOCX
  preferences.md       # Job matching rules
  profile.md           # Work history from interview
  linkedin-contacts.csv # LinkedIn connections (optional)
  jobs/                # Per-job application folders
  job-history.md       # Running log from job-search
```
