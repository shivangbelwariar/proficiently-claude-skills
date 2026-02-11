# Resume Tailoring Skill for Claude Code

Create tailored resumes that make you the obvious candidate for any specific job posting. Uses your existing resume (from the job-search skill) and an optional deep-dive work history interview to craft compelling, targeted resumes.

## Features

- **Work history assessment** - evaluates how much it knows about your background
- **Deep-dive interview** - structured conversation to capture the full depth of your experience
- **Job posting analysis** - fetches and parses job details from any URL
- **Intelligent tailoring** - rearranges, rewrites, and emphasizes the right experience
- **Level-appropriate framing** - calibrates language and emphasis to match the role's seniority

## Prerequisites

1. [Claude Code CLI](https://claude.ai/code) installed
2. [Claude in Chrome](https://chromewebstore.google.com/detail/claude-in-chrome) extension installed
3. Resume already set up via the [job-search skill](../job-search/) (`/job-search setup`)

## Setup

### 1. Configure permissions

Add to `~/.claude/settings.json`:

```json
{
  "permissions": {
    "allow": [
      "Read(~/.claude/skills/tailor-resume/**)",
      "Write(~/.claude/skills/tailor-resume/assets/**)",
      "Edit(~/.claude/skills/tailor-resume/assets/**)",
      "Read(~/.claude/skills/job-search/assets/resume/**)",
      "Read(~/.claude/skills/job-search/assets/matching-rules.md)",
      "mcp__claude-in-chrome__*"
    ]
  }
}
```

### 2. (Optional) Run the work history interview

```bash
claude "/tailor-resume interview"
```

This 15-20 minute conversation captures the depth of your experience - accomplishments, metrics, challenges, and context that don't fit on a resume but are essential for tailoring.

## Usage

### Tailor resume for a job

```bash
claude "/tailor-resume https://example.com/jobs/vp-growth"
```

### Run work history interview

```bash
claude "/tailor-resume interview"
```

### General flow

```bash
claude "/tailor-resume"
```

This will check your work history profile, offer an interview if needed, then ask for a job URL.

## File Structure

```
~/.claude/skills/tailor-resume/
├── SKILL.md                          # Main skill definition
├── README.md                         # This file
├── .gitignore                        # Excludes personal data
├── assets/
│   ├── work-history/
│   │   └── profile.md                # Your detailed work history (gitignored)
│   ├── tailored-resumes/             # Generated resumes (gitignored)
│   └── templates/
│       └── profile.md                # Work history template (committed)
└── scripts/
    ├── interview.md                  # Interview guide
    └── tailor.md                     # Tailoring agent prompt
```

## How It Works

1. **Reads your resume** from the job-search skill's assets
2. **Checks work history depth** - do we have enough detail to tailor effectively?
3. **Offers an interview** if gaps exist (only needs to happen once)
4. **Fetches the job posting** via browser automation
5. **Maps your experience** to the job's requirements
6. **Generates a tailored resume** with reordered bullets, rewritten descriptions, and a targeted summary
7. **Saves the output** for your review and iteration

## Tips

- The work history interview is the biggest unlock. A 15-minute conversation gives dramatically better tailored resumes.
- You can iterate on any generated resume - ask to adjust tone, emphasis, or specific bullets.
- Tailored resumes are saved with the company name and date, so you can track what you've sent where.
- The skill never fabricates experience - it reorganizes and reframes what's real.
