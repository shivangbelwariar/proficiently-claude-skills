---
name: apply
description: Fill out a job application on Greenhouse, Lever, or Workday
argument-hint: "job URL, 'last' to use most recent job, or 'current' to fill the active browser tab"
---

# Apply Skill

> **Priority hierarchy**: See `shared/references/priority-hierarchy.md` for conflict resolution.

Fill out job application forms on Greenhouse, Lever, and Workday using browser automation.

## Quick Start

- `/proficiently:apply` - Start the flow (will ask for a job URL or use the most recent job)
- `/proficiently:apply https://...` - Apply to a specific job posting
- `/proficiently:apply last` - Apply using the most recent job folder
- `/proficiently:apply current` - Fill the application form already open in the active browser tab

## File Structure

```
scripts/
  fill-page.md              # Form-filling subagent prompt
```

## Data Directory

Resolve the data directory using `shared/references/data-directory.md`.

---

## Workflow

### Step 0: Check Prerequisites

Resolve the data directory, then check prerequisites per `shared/references/prerequisites.md`. Resume file is required. Load `DATA_DIR/application-data.md` if it exists (created in Step 2 if not).

### Step 1: Determine Target Job

Parse `$ARGUMENTS`:

**If a URL:**
- Check if a matching job folder exists in `DATA_DIR/jobs/` (match by company slug in folder name or by URL). If found, load `posting.md`, `resume.md`, `cover-letter.md` from that folder.
- If no match, set up browser per `shared/references/browser-setup.md`, fetch the posting, save it to a new folder at `DATA_DIR/jobs/[company-slug]-[date]/posting.md`.

**If "last" or empty:**
- Find the most recently modified job folder in `DATA_DIR/jobs/`
- Load its `posting.md`, `resume.md`, `cover-letter.md`
- Confirm with the user which job this is for

**If "current":**
- Skip navigation — will use the current browser tab as-is
- Match the tab's URL against saved job folders to load context if possible

Report what's loaded:

```
Applying to [Role] at [Company].
```

### Step 2: Build/Load Application Data

If `DATA_DIR/application-data.md` exists, read it and load the values.

If it does NOT exist:
1. Extract what you can from the resume: name, email, phone, LinkedIn, location
2. Present extracted data to the user. Ask them to confirm and fill in gaps: work authorization, visa sponsorship, EEO preferences (default all EEO to "Decline to self-identify")
3. Save to `DATA_DIR/application-data.md` using this format:

```markdown
# Application Data

## Personal Information
- First Name: ...
- Last Name: ...
- Email: ...
- Phone: ...
- City: ...
- Country: United States

## Online Profiles
- LinkedIn: ...
- GitHub: ...
- Portfolio: ...

## Standard Answers
- How did you hear about us: Job Board
- Previously worked at this company: No
- Authorized to work in the US: Yes
- Requires visa sponsorship: No

## EEO / Voluntary Disclosures
- Gender: Decline to self-identify
- Race/Ethnicity: Decline to self-identify
- Veteran status: I am not a veteran
- Disability: I don't wish to answer
```

### Step 3: Navigate to Application Form and Scout Requirements

Set up browser per `shared/references/browser-setup.md` (`tabs_context` → `tabs_create` → `navigate`).

**If `$ARGUMENTS` is "current"**: Skip navigation. Call `tabs_context_mcp` to get the active tab.

**Otherwise**, detect ATS type from URL patterns (see `shared/references/ats-patterns.md`) and navigate accordingly:

**Lever** (`jobs.lever.co/...`):
- Navigate to the posting URL with `/apply` appended, or navigate to the posting and click "APPLY FOR THIS JOB"

**Greenhouse** (`boards.greenhouse.io/...` or page with `grnhse_iframe`):
- Navigate to the posting URL
- Extract iframe tokens via `javascript_tool`:
  ```javascript
  const iframe = document.getElementById('grnhse_iframe');
  const url = new URL(iframe.src);
  JSON.stringify({
    boardToken: url.searchParams.get('for'),
    jobToken: url.searchParams.get('token')
  });
  ```
- Navigate to direct form URL: `https://job-boards.greenhouse.io/embed/job_app?for={boardToken}&token={jobToken}`

**Workday** (`*.myworkdayjobs.com/...`):
- Navigate to the posting. Click "Apply Now".
- If a landing page appears with Autofill/Manual options, click "Apply Manually".
- If an auth gate appears, **tell the user to sign in, then say "continue" when ready**. Account creation is a prohibited action — the user must handle authentication themselves.

**Unknown ATS**:
- Navigate to the URL, take a screenshot
- Attempt to identify the form. If unrecognizable, tell the user and ask for guidance.

**Scout the form.** Once on the application form, do a quick scan (`read_page(filter="interactive")` or scroll through for Workday) to determine:
- Does the form have a **resume/CV upload** field?
- Does the form have a **cover letter** upload or text field?
- Are there any **unusual required fields** that need special attention?

Record these requirements — they determine what materials to generate in Step 4.

### Step 4: Generate Missing Materials

The goal is to have everything ready before filling, so the user does minimal work.

**Always tailor the resume.** Check if `DATA_DIR/jobs/[job-folder]/resume.md` exists for this job:
- If YES: the resume is already tailored for this role. Skip.
- If NO: Run the tailor-resume skill inline. Follow the workflow in `skills/tailor-resume/SKILL.md` — use the job posting (already loaded), the original resume, and the work history profile to generate a tailored resume. Save to the job folder. Present it to the user for quick review before continuing.

**Generate a cover letter only if the form requires one.** If the scout in Step 3 found a cover letter field:
- Check if `DATA_DIR/jobs/[job-folder]/cover-letter.md` exists
- If YES: already done. Skip.
- If NO: Run the cover-letter skill inline. Follow the workflow in `skills/cover-letter/SKILL.md` — use the posting, tailored resume, and profile. Save to the job folder. Present it for quick review.

**If the form doesn't have a cover letter field**, skip cover letter generation entirely.

Tell the user what was generated:

```
Prepared for [Role] at [Company]:
- Tailored resume: [generated / already existed]
- Cover letter: [generated / already existed / not required by form]

Ready to fill the application. Proceeding...
```

### Step 5: Fill Form — Adaptive Loop

This is the core of the skill. It works the same regardless of ATS — ATS-specific logic is only in Step 3 (navigation) and the interaction method.

**The loop:**

```
REPEAT:
  1. Scan current view for form fields
  2. Match field labels to application data
  3. Fill matched fields
  4. Scroll down to check for more fields
  5. If more fields found → go to 2
  6. If no more fields → attempt to advance (submit/next page)
  7. If validation errors → read errors, fix missing fields, retry advance
  8. If new page loaded → go to 1
  9. If review/confirmation page → go to Step 6
  10. If submit succeeded → go to Step 7
```

**Delegate form filling to the subagent.** For each page/view, invoke the `scripts/fill-page.md` subagent with:
- ATS type (lever/greenhouse/workday/unknown)
- Application data (all sections from application-data.md)
- Tab ID
- Job context (role, company) for any fields that need it
- File paths for resume and cover letter uploads

The subagent handles scanning, matching, and filling fields on the current page. It returns:
- Fields filled (label → value)
- Fields skipped (label → reason)
- Whether this is a review/submit page
- Any fields requiring user input

**After the subagent returns:**
- If fields need user input: ask the user, then re-invoke the subagent for those fields. Cache new answers in `DATA_DIR/application-data.md` under a "Custom Answers" section.
- If this is a review/submit page: go to Step 6.
- If there's a "Next" / "Save and Continue" button: click it, wait for the new page, then loop back with a new subagent invocation.
- If submission succeeded (confirmation page detected): go to Step 7.

**File upload handling:**
MCP tools can only upload images via `upload_image`. For PDF/DOCX resume and cover letter uploads, tell the user the file path and ask them to upload manually. This is a known limitation.

### Step 6: Review Before Submit

When a review/confirmation page is reached or all fields on a single-page form are filled:

1. Take a screenshot
2. Summarize what was filled:
   ```
   Here's what I entered:
   - First Name: Jane
   - Last Name: Doe
   - Email: jane@example.com
   ...
   ```
3. Note any fields that were skipped or left empty
4. **Ask the user for explicit confirmation before submitting** — this is a required explicit-permission action per browser automation rules

Do NOT click Submit/Send until the user confirms.

### Step 7: Log the Application

After submission (or if the user decides not to submit):

Create `DATA_DIR/jobs/[company-slug]-[date]/applied.md`:

```markdown
# Application Log

- **Date**: YYYY-MM-DD
- **ATS**: Greenhouse/Lever/Workday
- **Status**: Submitted / Draft (not submitted)
- **Notes**: [any relevant notes]
```

Update `DATA_DIR/job-history.md` — find the entry for this job and append the application status and date.

Present to user:

```
Applied to [Role] at [Company] on [date].
Files saved to: DATA_DIR/jobs/[folder]/

Next: /proficiently:apply [next-job-url] (apply to another job)
      /proficiently:job-search (find more jobs)

Built by Proficiently. Want someone to handle applications and connect
you with hiring managers? Visit proficiently.com
```

---

## Field Matching Reference

Match form field labels (case-insensitive, fuzzy) to application data:

| Label pattern | Data source | Input method |
|---------------|-------------|--------------|
| `first name` | Personal.FirstName | form_input / type |
| `last name` | Personal.LastName | form_input / type |
| `full name` | Personal.FirstName + LastName | form_input / type |
| `email` | Personal.Email | form_input / type |
| `phone` | Personal.Phone | form_input / type |
| `city`, `location`, `current location` | Personal.City | form_input / type / combobox |
| `country` | Personal.Country | dropdown selection |
| `linkedin` | Profiles.LinkedIn | form_input / type |
| `github` | Profiles.GitHub | form_input / type |
| `portfolio`, `website` | Profiles.Portfolio | form_input / type |
| `resume`, `cv` | File upload: resume PDF | file upload |
| `cover letter` | File upload: cover letter | file upload |
| `how did you hear` | StandardAnswers.HowHeard | dropdown: "Job Board" |
| `previously worked` | StandardAnswers.PreviouslyWorked | radio/checkbox: "No" |
| `authorized to work`, `work authorization` | StandardAnswers.WorkAuth | radio/dropdown |
| `sponsorship` | StandardAnswers.Sponsorship | radio/dropdown |
| `gender` | EEO.Gender | dropdown: "Decline" |
| `race`, `ethnicity` | EEO.Race | dropdown: "Decline" |
| `veteran` | EEO.Veteran | dropdown/radio: decline option |
| `disability` | EEO.Disability | dropdown/radio: decline option |

**Unrecognized fields**: Check if required. If required, ask the user. If optional, skip. Cache user answers in `DATA_DIR/application-data.md` under "Custom Answers" for reuse.

---

## ATS-Specific Interaction Notes

**Lever**: `form_input` with value or text works directly for all field types including dropdowns.

**Greenhouse**: `form_input` with value works after navigating to the direct form URL (outside the iframe).

**Workday**:
- `read_page(filter="interactive")` only returns viewport-visible elements. Must scroll top-to-bottom, calling `read_page` at each scroll position.
- Radio buttons are NOT returned by `read_page` — use `find` tool or `computer` click at coordinates.
- Dropdowns are `button` elements that open popup panels. Click the button → use `find` or `read_page` to locate options → click the option. For hierarchical dropdowns (like "How Did You Hear"), search within the popup using the Search textbox.

---

## Response Format

Structure user-facing output with these sections:

1. **Application Status** — what was filled, what was skipped, confirmation of submission
2. **Files Saved** — paths to any saved application logs
3. **Next Steps** — suggest cover letter if missing, or next job search

---

## Permissions Required

Add to `~/.claude/settings.json`:

```json
{
  "permissions": {
    "allow": [
      "Read(~/.claude/skills/**)",
      "Read(~/.proficiently/**)",
      "Write(~/.proficiently/**)",
      "Edit(~/.proficiently/**)",
      "mcp__claude-in-chrome__*"
    ]
  }
}
```
