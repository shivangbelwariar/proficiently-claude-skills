# Data Directory

All personal data lives here. Everything in this directory (except this README) is gitignored.

## Structure

```
data/
├── README.md            # This file (committed)
├── resume/              # Your resume PDF or DOCX
├── profile.md           # Detailed work history (built via /tailor-resume interview)
├── preferences.md       # Job matching rules (built via /job-search setup)
├── job-history.md       # Running log of all jobs found by /job-search
├── jobs/                # One folder per job application
│   ├── google-lead-gpm-2026-02-11/
│   │   ├── posting.md       # Saved job description
│   │   ├── resume.md        # Tailored resume
│   │   └── cover-letter.md  # Cover letter
│   └── ...
└── logs/                # Cron job logs
```

## How it gets populated

| File | Created by | Command |
|------|-----------|---------|
| `resume/` | You (manually) | Place your resume here, or run `/job-search setup` |
| `preferences.md` | `/job-search setup` | Interactive preference configuration |
| `profile.md` | `/tailor-resume interview` | 15-20 min work history deep-dive |
| `job-history.md` | `/job-search` | Appended automatically after each search |
| `jobs/[slug]/posting.md` | `/tailor-resume` | Saved when fetching a job posting |
| `jobs/[slug]/resume.md` | `/tailor-resume` | Generated tailored resume |
| `jobs/[slug]/cover-letter.md` | `/cover-letter` | Generated cover letter |

## Getting started

1. Add your resume: `cp ~/your-resume.pdf ~/.claude/skills/data/resume/`
2. Set up preferences: `claude "/job-search setup"`
3. (Recommended) Build your work history: `claude "/tailor-resume interview"`
