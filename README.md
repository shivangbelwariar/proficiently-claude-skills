# Proficiently Claude Skills

A suite of Claude Code skills for AI-powered job searching, resume tailoring, and cover letter writing.

## Skills

| Skill | Command | Description |
|-------|---------|-------------|
| [Job Search](./job-search/) | `/job-search` | Automated job search on hiring.cafe with smart filtering |
| [Tailor Resume](./tailor-resume/) | `/tailor-resume` | Create tailored resumes for specific job postings |
| [Cover Letter](./cover-letter/) | `/cover-letter` | Write natural, persuasive cover letters |

## How They Work Together

1. **`/job-search`** finds jobs that match your preferences and resume
2. **`/tailor-resume`** rewrites your resume for a specific job posting, saves the job posting and tailored resume together
3. **`/cover-letter last`** writes a cover letter using the most recent job's posting and tailored resume

All skills share a `data/` directory for personal files. Each job application gets its own folder containing the posting, tailored resume, and cover letter.

## Installation

### 1. Clone into your Claude skills directory

```bash
git clone https://github.com/proficientlyjobs/proficiently-claude-skills.git ~/.claude/skills
```

### 2. Add your resume

```bash
cp /path/to/your/resume.pdf ~/.claude/skills/data/resume/
```

### 3. Configure permissions

Add to `~/.claude/settings.json`:

```json
{
  "permissions": {
    "allow": [
      "Read(~/.claude/skills/**)",
      "Write(~/.claude/skills/data/**)",
      "Edit(~/.claude/skills/data/**)",
      "Bash(crontab *)",
      "mcp__claude-in-chrome__*"
    ]
  }
}
```

### 4. Run setup

```bash
claude "/job-search setup"
```

This will verify your resume and configure your job preferences.

## Prerequisites

- [Claude Code CLI](https://claude.ai/code)
- [Claude in Chrome](https://chromewebstore.google.com/detail/claude-in-chrome) extension (for browser automation)
- Chrome browser running with the extension active

## File Structure

```
~/.claude/skills/
├── data/                                # All personal data (gitignored)
│   ├── resume/                          # Your resume PDF/DOCX
│   ├── profile.md                       # Work history from interview
│   ├── preferences.md                   # Job matching rules
│   ├── job-history.md                   # Running log from job-search
│   ├── jobs/                            # One folder per application
│   │   ├── google-lead-gpm-2026-02-11/
│   │   │   ├── posting.md               # Saved job description
│   │   │   ├── resume.md                # Tailored resume
│   │   │   └── cover-letter.md          # Cover letter
│   │   └── ...
│   └── logs/
├── job-search/
│   ├── SKILL.md
│   ├── assets/templates/
│   └── scripts/
├── tailor-resume/
│   ├── SKILL.md
│   ├── assets/templates/
│   └── scripts/
└── cover-letter/
    ├── SKILL.md
    └── scripts/
```

All personal data (resume, preferences, generated documents) is gitignored and stays local.

## License

MIT
