# Proficiently — Session Bootstrap

## CRITICAL: Data Directory is Already Set Up

`~/.proficiently/` exists and is fully configured. It contains:
- `resume/` — resume PDF and resume.md
- `preferences.md` — job search preferences
- `application-data.md` — personal info for applications
- `profile.md` — work history profile
- `job-history.md` — application tracking

**NEVER ask the user to run `/proficiently:setup` or say the data directory is missing.**
**NEVER stop because setup is not done — it IS done.**

## DATA_DIR = ~/.proficiently/

All proficiently skills must use `~/.proficiently/` as DATA_DIR. Do not use the session's working directory. Do not create a new `.proficiently/` folder. Always use the one at `~/.proficiently/`.

## linkedin-search Skill

The `/proficiently:linkedin-search` skill exists. It:
- Scrapes LinkedIn job listings via `python-jobspy` (NO browser login required)
- Calls `python3 <skill_dir>/scripts/jobspy_search.py`
- Default params: search="software engineer", location="San Francisco Bay Area", hours=168
- Supports `--offset` for pagination (3 pages × 50 = 150 results)
- Skips Easy Apply-only jobs (requires LinkedIn login, which we don't do)

## job-search Skill (hiring.cafe)

The `/proficiently:job-search` skill uses hiring.cafe with the default URL stored in `~/.proficiently/preferences.md` under `## Default Search URLs > Hiring.cafe`. Navigate to that URL directly — do NOT type search terms manually when no arguments are given.

## No Fabrication Rule

When filling job applications, ONLY use data from `~/.proficiently/application-data.md`.
- School: ONLY "Rajasthan Technical University, Kota" — never SJSU, never any other school
- If a dropdown doesn't have RTU → select "Other" or leave blank
- Never invent any personal data
