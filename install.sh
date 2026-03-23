#!/bin/bash
# Install proficiently-claude-skills
# Usage: git clone https://github.com/shivangbelwariar/proficiently-claude-skills && cd proficiently-claude-skills && ./install.sh

set -e
REPO_DIR="$(cd "$(dirname "$0")" && pwd)"

echo ""
echo "======================================"
echo " proficiently-claude-skills installer"
echo "======================================"
echo ""

# ── 1. Install skill files ──────────────────────────────────────────────────
echo "==> Installing skills into ~/.claude/skills/proficiently/ ..."
mkdir -p ~/.claude/skills/proficiently
for skill_dir in "$REPO_DIR"/skills/*/; do
  skill_name="$(basename "$skill_dir")"
  dst="$HOME/.claude/skills/proficiently/$skill_name"
  [ -L "$dst" ] && rm "$dst"           # remove stale symlink if present
  rsync -a --delete "$skill_dir" "$dst/"
  echo "    ✓ $skill_name"
done

# ── 2. Create ~/.proficiently/ data directory ───────────────────────────────
echo ""
echo "==> Setting up ~/.proficiently/ data directory ..."
mkdir -p ~/.proficiently/resume ~/.proficiently/jobs

# Copy CLAUDE.md (session bootstrap — tells Claude where data lives)
cp "$REPO_DIR/CLAUDE.md" ~/.proficiently/CLAUDE.md
echo "    ✓ CLAUDE.md"

# Copy preferences template if not already set up
if [ ! -f ~/.proficiently/preferences.md ]; then
  cp "$REPO_DIR/preferences.md" ~/.proficiently/preferences.md
  echo "    ✓ preferences.md (template — edit with your target roles and location)"
else
  echo "    ~ preferences.md already exists, skipped"
fi

# Create application-data.md template if not present
if [ ! -f ~/.proficiently/application-data.md ]; then
  cat > ~/.proficiently/application-data.md << 'EOF'
# Application Data
# SINGLE SOURCE OF TRUTH — Fill in ALL fields. Claude uses ONLY this file.
# NEVER fabricate any field not listed here.

## File Paths
- Resume PDF: ~/.proficiently/resume/your-resume.pdf

## Personal Information
- First Name:
- Last Name:
- Preferred Name:
- Email:
- Phone:
- Birthday: YYYY-MM-DD
- City:
- State:
- Postal Code:
- Address:
- Address 2: (none)
- Country: United States
- Country Code: US

## Online Profiles
- LinkedIn:
- GitHub: (none — leave blank)
- Portfolio: (none — leave blank)

## Standard Answers
- How did you hear about us: Job Board
- Previously worked at this company: No
- Authorized to work in the US: Yes
- Requires visa sponsorship: No
- Will you now or in the future require sponsorship: No

## EEO / Voluntary Disclosures
- Gender:
- Race / Ethnicity:
- Veteran status: No / I am not a protected veteran
- Disability: No / I do not have a disability

## Education
- University / School:
- Degree Type:
- Field of Study / Major:
- Graduation Year:

## Work Experience — Job 1 (Current)
- Company:
- Title:
- Start Month:
- Start Year:
- End: Present (currently employed)

## Work Experience — Job 2 (Previous)
- Company:
- Title:
- Start Month:
- Start Year:
- End Month:
- End Year:

## Overall Experience
- Total Years of Experience:

## Skills
(comma-separated list of your skills)

## Custom Answers
- Salary Expectation:
- Start Date / Availability: 2 weeks notice
- Onsite / Hybrid: Yes (willing to work onsite or hybrid)
- Relocation: No

## Login Credentials
- Email:
- Password:
- Note: If account doesn't exist on a site, create it with these credentials.
- OTP/Verification: Use Gmail MCP connector (mcp__claude_ai_Gmail__gmail_search_messages) to retrieve OTPs
EOF
  echo "    ✓ application-data.md (template — fill in your details)"
else
  echo "    ~ application-data.md already exists, skipped"
fi

# Create job-history if missing
if [ ! -f ~/.proficiently/job-history.md ]; then
  echo "# Job Application History" > ~/.proficiently/job-history.md
  echo "    ✓ job-history.md"
fi

# ── 3. Install auto-sync hook ───────────────────────────────────────────────
HOOK_SCRIPT="$HOME/claude-skills-autopush.sh"
cat > "$HOOK_SCRIPT" << HOOK
#!/bin/bash
# Auto-sync proficiently skills → git repo on every Claude session end
REPO="$REPO_DIR"
for skill in apply job-search linkedin-search cover-letter tailor-resume network-scan setup; do
  src="\$HOME/.claude/skills/proficiently/\$skill"
  dst="\$REPO/skills/\$skill"
  [ -d "\$src" ] && rsync -a --delete "\$src/" "\$dst/"
done
cd "\$REPO"
git add skills/ 2>/dev/null
if ! git diff --staged --quiet; then
  git commit -m "auto-backup: \$(date '+%Y-%m-%d %H:%M')" 2>/dev/null
  git push origin main 2>/dev/null
fi
HOOK
chmod +x "$HOOK_SCRIPT"
echo ""
echo "==> Auto-sync hook installed: $HOOK_SCRIPT"

# ── 4. Summary ──────────────────────────────────────────────────────────────
echo ""
echo "======================================"
echo " Installation complete!"
echo "======================================"
echo ""
echo "REQUIRED — do these before using:"
echo ""
echo "  1. Copy your resume PDF to:"
echo "     ~/.proficiently/resume/"
echo "     Then update the path in ~/.proficiently/application-data.md"
echo ""
echo "  2. Fill in ~/.proficiently/application-data.md"
echo "     (name, email, phone, work history, skills, login credentials)"
echo ""
echo "  3. Edit ~/.proficiently/preferences.md"
echo "     (target roles, location, salary, dealbreakers)"
echo ""
echo "  4. In Claude Code — enable these plugins (Settings → Plugins):"
echo "     • superpowers"
echo "     • chrome-devtools-mcp"
echo "     • playwright"
echo "     • context7"
echo "     • claude-md-management"
echo ""
echo "  5. Install the 'Claude in Chrome' Chrome extension"
echo "     (search Claude Code docs or Chrome Web Store for it)"
echo ""
echo "  6. Set up Gmail MCP for OTP retrieval"
echo "     (run: claude mcp add gmail ... — see Claude Code docs)"
echo ""
echo "THEN start with:"
echo "  /job-search          — search hiring.cafe with default filters"
echo "  /linkedin-search     — search LinkedIn jobs"
echo "  /apply <url>         — apply to a specific job"
echo ""
