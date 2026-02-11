---
name: cover-letter
description: Write a tailored cover letter for a specific job posting
argument-hint: "job URL, or 'last' to use the most recent job"
---

# Cover Letter Skill

Write natural, persuasive cover letters that sound like a real professional wrote them.

## Quick Start

- `/cover-letter` - Start the flow (will ask for a job URL)
- `/cover-letter https://...` - Write a cover letter for a specific job posting
- `/cover-letter last` - Write a cover letter for the most recent job in data/jobs/

## File Structure

```
scripts/
  write-cover-letter.md       # Cover letter writing agent prompt
```

Shared data (all skills read/write here):
```
../data/
  resume/                     # Source resume
  profile.md                  # Work history from interview
  jobs/                       # Per-job application folders
    [company-slug]/
      posting.md              # Saved job description
      resume.md               # Tailored resume (from tailor-resume skill)
      cover-letter.md         # Cover letter (written by this skill)
```

---

## Workflow

### Step 0: Load Context

Read:
- `../data/resume/*` (original resume)
- `../data/profile.md` (work history, if it exists)

If no resume found, tell user to run `/job-search setup`.
If no work history profile, warn that the cover letter will be based only on the resume (recommend running `/tailor-resume interview` first for better results).

### Step 1: Get Job Details

**If `$ARGUMENTS` is "last" or empty:**
- Check `../data/jobs/` for the most recently modified folder
- If found, read `posting.md` and `resume.md` from that folder
- Confirm with the user which job this is for
- If no job folders exist, ask the user for a job URL

**If `$ARGUMENTS` is a URL:**
- Check if a job folder already exists for this company in `../data/jobs/`
- If yes, read the existing `posting.md` and `resume.md`
- If no, use Claude in Chrome MCP tools to fetch the job posting:
  ```
  1. tabs_context_mcp -> get browser state
  2. tabs_create_mcp -> new tab
  3. navigate -> job URL
  4. get_page_text -> extract full job posting
  ```
- Save the posting to `../data/jobs/[company-slug]-[date]/posting.md` if not already saved

If the page can't be loaded, ask the user to paste the job description directly.

### Step 2: Gather Materials

For the target job folder, check what exists:
- `posting.md` - the job description (required)
- `resume.md` - a tailored resume (optional, improves quality significantly)

If no tailored resume exists, use the original resume and work history profile directly.

### Step 3: Write the Cover Letter

Follow the framework in `scripts/write-cover-letter.md`. Use:
- The work history profile (or original resume if no profile)
- The tailored resume for this role (if available)
- The job posting

The cover letter must:
- Be 250-350 words
- Start with "Dear Hiring Manager,"
- End with "Regards, [Name]"
- Use ONLY hyphens, never em dashes
- Sound like a real human wrote it
- Never fabricate or exaggerate any detail
- Connect 2-3 specific, measurable achievements to the employer's needs

### Step 4: Present and Save

Save to `../data/jobs/[company-slug]-[date]/cover-letter.md`

Present the cover letter to the user with:
- The full text
- A brief note on which achievements were highlighted and why
- The file path where it's saved

### Step 5: Iterate

Ask if the user wants to adjust:
- Tone (more formal, more casual, more technical)
- Which achievements to highlight
- Specific phrasing
- Length

Apply changes and re-save.

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
      "mcp__claude-in-chrome__*"
    ]
  }
}
```
