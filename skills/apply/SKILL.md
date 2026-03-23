---
name: apply
description: Fill out a job application on Greenhouse, Lever, or Workday
argument-hint: "job URL, 'last' to use most recent job, or 'current' to fill the active browser tab"
---

# Apply Skill

## ABSOLUTE RULE: NO FABRICATION

You MUST ONLY use data explicitly stored in `DATA_DIR/application-data.md`.
If a field asks for information not in application-data.md:
- Dropdown → select "Other", "Prefer not to say", "N/A", or the most neutral option
- Text field → type "N/A" or leave blank if optional
- NEVER invent, guess, or fabricate ANY personal information including but not limited to:
  school names, company names, dates, addresses, phone numbers, URLs, GPA, salary history
This rule has NO exceptions. Violating it causes real damage to the applicant.

### SCHOOL FIELD HARD RULE
The only acceptable school value is **"Rajasthan Technical University, Kota"** (stored in application-data.md).
- If the school field is a **text input**: type "Rajasthan Technical University, Kota" exactly.
- If the school field is a **dropdown** and "Rajasthan Technical University" is NOT in the list:
  → Select "Other" or the most neutral/blank option. DO NOT pick any other university.
  → NEVER select SJSU, SJSU, UC Berkeley, Stanford, or any other school that is not RTU.
- If there is NO "Other" option in the dropdown: leave the field blank or skip it entirely.
- There is no "best match" or "closest option" for school — it is RTU or nothing.

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
- If an auth gate appears, **handle it automatically** — do NOT ask the user to sign in:
  1. Load credentials from `DATA_DIR/application-data.md` (Login Credentials section): email `REDACTED_EMAIL`, password `REDACTED_PASSWORD`
  2. Enter the email and password on the sign-in form and submit
  3. If the account doesn't exist, click "Create Account" / "Sign Up" and register with the same credentials
  4. If OTP or email verification is required, use Gmail MCP (`mcp__claude_ai_Gmail__gmail_search_messages` with query `"verification" OR "OTP" OR "confirm" OR "activate"`) to retrieve the code or link, then enter it
  5. Once signed in, continue to the application form

**Unknown ATS**:
- Navigate to the URL, take a screenshot
- Attempt to identify the form. If unrecognizable, tell the user and ask for guidance.

### Step 3.5: Try Simplify Autofill First

**Always attempt Simplify before any manual filling.** Simplify handles ~70-80% of Greenhouse, Lever, Workday, iCIMS, and Jobvite forms automatically.

1. Wait 2 seconds for the page to fully load
2. **Zoom into the bottom-right corner** to check for the Simplify icon:
   ```
   computer(action="zoom", region=[1100, 500, 1312, 768])
   ```
   The Simplify icon is a small gray/silver rounded square with 3-4 horizontal white stripes (stacked lines).
3. **If the Simplify icon is visible:**
   - Click it to trigger autofill
   - Wait 3 seconds for Simplify to fill the form
   - **Correct these fields immediately after Simplify fills** (Simplify often gets them wrong):
     - **School/University**: Simplify may fill wrong school — overwrite with "Rajasthan Technical University, Kota" (or "Other" if dropdown)
     - **Field of Study**: must be "Computer Engineering" exactly
     - **Graduation Year**: must be 2019
   - **Then verify REQUIRED (*) fields only** — do not touch optional fields:
     - Use `find("*")` and `find("Required")` to get the required-field inventory
     - Use `find("Select One")` to catch unfilled required dropdowns
     - Scroll top-to-bottom checking every required (*) field has a real value
     - Fill any still-empty required (*) fields using `application-data.md` — skip optional ones
   - Skip to **Step 7**, passing `simplify_already_filled: true` to the fill-page subagent
4. **If no Simplify icon appears after 3 seconds:**
   - Simplify doesn't support this form — continue with manual Steps 5-7 below

**Scout the form.** Once on the application form, do a quick scan (`read_page(filter="interactive")` or scroll through for Workday) to determine:
- Does the form have a **resume/CV upload** field?
- Does the form have a **cover letter** upload or text field?
- Are there any **unusual required fields** that need special attention?

Record these requirements — they determine what materials to generate in Step 4.

### Step 4: Prepare Materials

**Resume: NEVER tailor. Always use the original resume as-is.**
Use `DATA_DIR/resume/` — find the PDF or DOCX file there and use it directly for every application. Do not run tailor-resume, do not modify it in any way.

**Cover letter: only if the form requires one.** If the scout in Step 3 found a cover letter field:
- Check if `DATA_DIR/jobs/[job-folder]/cover-letter.md` exists
- If YES: already done. Skip.
- If NO: Run the cover-letter skill inline. Follow the workflow in `skills/cover-letter/SKILL.md` — use the posting and profile. Save to the job folder. Proceed without user review.

**If the form doesn't have a cover letter field**, skip cover letter generation entirely.

### Step 5: Build Required-Field Inventory

Before filling anything, identify **only the required (*) fields**. Optional fields are ignored entirely — do not add them to the filling list.

**Run this JS to get required fields:**
```javascript
Array.from(document.querySelectorAll('label, [aria-required="true"], [required]'))
  .filter(el => el.innerText?.includes('*') || el.getAttribute('aria-required') === 'true' || el.hasAttribute('required'))
  .map(el => ({ label: el.innerText?.replace(/\*/g,'').trim(), ref: el.htmlFor || el.id || '' }))
  .filter(f => f.label)
```

Also run `find("*")`, `find("Required")`, `find("Select One")` to catch anything the JS misses (especially radio buttons and Workday dropdowns).

**For Workday (multi-page):** scroll TOP to BOTTOM running the JS at each viewport — required fields may be below the fold. Use `find("Yes")` / `find("No")` to find required radio buttons invisible to JS.

**Result: a complete required-field inventory** — every field that must be filled before submission. This is the ONLY list used in Step 6.

**Exceptions — always include regardless of required status:**
- Resume/CV upload field
- Cover letter upload/text field (if present)
- Privacy policy / terms checkboxes

### Step 6: Auto-Fill Required Fields Only (No Approval Needed)

**Only generate answers for fields in the required-field inventory from Step 5. Skip all optional fields.**

Generate an answer for each required field using this priority:
1. **Application data** — match from `application-data.md` per the Field Matching Reference below
2. **Reasonable defaults** — for common fields not in application data:
   - Legal First/Last Name → same as First/Last Name
   - Electronic signature → full name
   - Arbitration/terms agreements → Accept
   - Interview process acknowledgments → Accept
   - AI transcription consent → Accept
   - Contract/temp work questions → "No"
3. **Custom Answers** — check the "Custom Answers" section of `application-data.md` for previously cached answers
4. **Safe fallback for unknown fields** — if the field is NOT in application-data.md and has no reasonable default:
   - Dropdown: select "Other" or the closest neutral option — **NEVER invent a value not in the data**
   - Text field: leave blank if optional; if required, use the most conservative/neutral answer
   - **NEVER fabricate personal facts** (school names, company names, dates, numbers, locations) that are not explicitly stored in application-data.md
   - School/University fields: ONLY use `Education.University` from application-data.md ("Rajasthan Technical University") — never guess another school

**Auto-fill immediately without user approval.** Do not present a summary or ask for review. Generate the best answer for every field and proceed directly to Step 7 to fill the form.

Cache any new field answers in `DATA_DIR/application-data.md` under a "Custom Answers" section so they're reused on future applications.

### Step 7: Fill Form

After approval, fill everything in one pass.

**Delegate to the subagent.** Invoke `scripts/fill-page.md` with:
- ATS type (lever/greenhouse/workday/unknown)
- The approved field→value mapping (all answers, not just application data)
- Tab ID
- File paths for resume and cover letter uploads
- `simplify_already_filled: true` if Simplify was used in Step 3.5 (so subagent verifies instead of re-filling)

The subagent fills all fields on the current page, then returns what was filled and what remains.

**For multi-page forms (Workday):**
1. Invoke the fill-page subagent — it scrolls the ENTIRE page and fills all fields including below-fold
2. **Verify before advancing** — after the subagent returns, do your own verification scroll top-to-bottom:
   - Check every required (*) field has a real value (not empty, not "Select One", not placeholder)
   - Use `find("Select One")` to catch any unfilled dropdowns
   - Use `find("Required")` to find any required fields still showing as empty
   - If anything is still empty, fill it NOW before proceeding
3. Only after ALL required fields verified → click "Save and Continue"
4. If validation errors still appear: read ALL errors at once, fix ALL of them in one pass, retry once
5. On the new page: scan ALL fields (Step 5 logic — full scroll + find), match answers, fill, verify, advance
6. Repeat until reaching the review page

**File upload handling:**
For resume/cover letter file uploads:
1. Try `upload_image` with the file path (works for some forms)
2. If that fails, use `javascript_tool` to programmatically set the file input value
3. If both fail, log the field as "upload-skipped" and continue — do NOT stop or ask the user

### Step 8: Auto-Submit

When a review/confirmation page is reached or all fields on a single-page form are filled:

1. Take a screenshot and save it to `DATA_DIR/jobs/[company-slug]-[date]/screenshot.png` for records
2. Click Submit/Send/Apply automatically — do not ask the user for confirmation

### Step 9: Log the Application

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
| `first name` | Personal.FirstName → "Fnu" | form_input / type |
| `last name` | Personal.LastName → "Palak" | form_input / type |
| `full name` | Personal.FirstName + LastName → "Fnu Palak" | form_input / type |
| `email` | Personal.Email → "REDACTED_EMAIL" | form_input / type |
| `phone` | Personal.Phone → "+14084228901" | form_input / type |
| `city`, `location`, `current location` | Personal.City → "San Jose" | form_input / type / combobox |
| `state` | Personal.State → "California" | dropdown / type |
| `zip`, `postal code` | Personal.PostalCode → "95132" | form_input / type |
| `address` | Personal.Address → "1880 Tradan Dr" | form_input / type |
| `country` | Personal.Country → "United States" | dropdown selection |
| `linkedin` | Profiles.LinkedIn | form_input / type |
| `github` | Profiles.GitHub → leave blank | skip if optional |
| `portfolio`, `website` | Profiles.Portfolio → leave blank | skip if optional |
| `resume`, `cv` | File upload: resume PDF | file upload |
| `cover letter` | File upload: cover letter | file upload |
| `how did you hear` | "Job Board" or "LinkedIn" | dropdown |
| `previously worked` | "No" | radio/checkbox |
| `authorized to work`, `work authorization` | "Yes" | radio/dropdown |
| `sponsorship`, `visa sponsorship` | "No" | radio/dropdown |
| `gender` | "Female" | dropdown |
| `race`, `ethnicity` | "Two or More Races" or "Asian" or "Decline" | dropdown |
| `veteran` | "I am not a protected veteran" or "No" | dropdown/radio |
| `disability` | "No, I do not have a disability" or "No" | dropdown/radio |
| `school`, `university`, `college`, `institution` | Education.University → "Rajasthan Technical University" | form_input / dropdown / type |
| `degree`, `education level` | Education.Degree → "Bachelor's" | dropdown / type |
| `field of study`, `major` | Education.FieldOfStudy → "Computer Engineering" | form_input / type |
| `graduation year`, `grad year` | Education.GraduationYear → "2019" | form_input / dropdown |
| `current company`, `employer`, `current employer` | Work Experience — Job 1 (Current) → Company → "RAJNISH" | form_input / type |
| `current title`, `job title`, `current position` | Work Experience — Job 1 (Current) → Title → "Senior Software Engineer" | form_input / type |
| `previous company`, `prior employer`, `previous employer`, `former employer` | Work Experience — Job 2 (Previous) → Company → "Robert Bosch Venture Capital" (also "Bosch") | form_input / type |
| `previous title`, `prior role`, `previous position` | Work Experience — Job 2 (Previous) → Title → "Senior Software Engineer" | form_input / type |
| `previous start date` | Work Experience — Job 2 (Previous) → Start → "September 2019" | form_input / type |
| `previous end date` | Work Experience — Job 2 (Previous) → End → "June 2023" | form_input / type |
| `years of experience` | Overall Experience → Total Years → "6" | form_input / dropdown |
| `salary`, `compensation`, `expected salary` | CustomAnswers.SalaryExpectation → "$130,000 - $160,000" | form_input / type |
| `start date`, `availability`, `notice period` | CustomAnswers.StartDate → "2 weeks" | form_input / type |
| `onsite`, `in-person`, `hybrid`, `in-office` | CustomAnswers.Onsite → "Yes" | radio/dropdown |
| `relocation` | CustomAnswers.Relocation → "No" | radio/dropdown |
| `visa status` | CustomAnswers.VisaStatus → "H4 EAD" | form_input / type |

**Unrecognized fields**: If optional → skip. If required → select "Other" for dropdowns, leave text fields blank. **NEVER invent personal facts not stored in application-data.md.** Cache any answers the user provides in "Custom Answers" for reuse.

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
