---
name: job-search
description: Search hiring.cafe for jobs matching my resume and preferences
argument-hint: "keyword to search, or 'setup' to configure"
---

# Job Search Skill

Automated daily job search using browser automation.

## Quick Start

- `/job-search` - Run daily search with default terms from matching rules
- `/job-search setup` - Configure preferences, resume, and cron schedule
- `/job-search AI infrastructure` - Search with specific keywords

## File Structure

```
scripts/
  evaluate-jobs.md     # Subagent for parallel job evaluation
assets/
  templates/           # Format templates (committed)
```

Shared data (all skills read/write here):
```
../data/
  resume/              # Your resume (gitignored)
  preferences.md       # Your job preferences (gitignored)
  job-history.md       # Running log of all jobs (gitignored)
  profile.md           # Work history from interview (gitignored)
  jobs/                # Per-job application folders (gitignored)
```

---

## Workflow

### Step 0: Setup Check

If `$ARGUMENTS` equals "setup" OR if `../data/preferences.md` does not exist or contains only template placeholders:

1. **Resume**: Check `../data/resume/` for resume files
   - If missing, ask user to provide path or paste content
   - Save to `../data/resume/`

2. **Preferences**: Ask user to fill in matching rules:
   - Target job titles
   - Must-have criteria (location, salary minimum)
   - Dealbreakers (agencies, crypto, travel, etc.)
   - Save to `../data/preferences.md`

3. **Automation**: Ask if user wants daily cron job
   - If yes, configure: `0 9 * * * claude -p "/job-search"`

Skip to Step 1 if setup is complete.

### Step 1: Load Context

Read these files:
- `../data/resume/*` (candidate profile)
- `../data/preferences.md` (preferences)
- `../data/job-history.md` (to avoid duplicates)

Extract search terms from:
1. `$ARGUMENTS` if provided
2. Target roles from preferences

### Step 2: Browser Search

Use Claude in Chrome MCP tools:

```
1. tabs_context_mcp → get browser state
2. tabs_create_mcp → new tab
3. navigate → https://hiring.cafe
4. For each search term:
   - Enter search query
   - Capture job listings (title, company, location, salary, link)
```

### Step 3: Evaluate Jobs

Spawn the evaluation subagent with:
- Candidate profile summary
- Matching rules
- Raw job listings

Reference: `scripts/evaluate-jobs.md`

The subagent returns scored jobs with fit ratings (High/Medium/Low/Skip).

### Step 4: Save History

Append ALL jobs to `../data/job-history.md` using format from `assets/templates/job-entry.md`:

```markdown
## [DATE] - Search: "[terms]"

| Job Title | Company | Location | Salary | Link | Fit | Notes |
|-----------|---------|----------|--------|------|-----|-------|
| ... | ... | ... | ... | ... | ... | ... |
```

### Step 5: Present Results

Show only NEW High/Medium fits not in previous history:

```markdown
## Top Matches for [DATE]

### 1. [Title] at [Company]
- **Fit**: High
- **Salary**: $XXXk
- **Location**: Remote
- **Why**: [reason]
- **Link**: [url]
```

### Step 6: Learn from Feedback

If user provides feedback, update `../data/preferences.md`:
- "No agencies" → add to dealbreakers
- "Prefer AI companies" → add to nice-to-haves
- "Minimum $350k" → update salary threshold

---

## Permissions Required

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
