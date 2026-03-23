#!/bin/bash
# Install proficiently-claude-skills on any machine
# Usage: git clone https://github.com/shivangbelwariar/proficiently-claude-skills && cd proficiently-claude-skills && ./install.sh

set -e
REPO_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "==> Installing proficiently-claude-skills..."

# 1. Install skills into ~/.claude/skills/proficiently/
mkdir -p ~/.claude/skills/proficiently
for skill in skills/*/; do
  skill_name="$(basename "$skill")"
  dst="$HOME/.claude/skills/proficiently/$skill_name"
  # Remove stale symlink or old copy
  [ -L "$dst" ] && rm "$dst"
  rsync -a --delete "$REPO_DIR/$skill" "$dst/"
  echo "    Installed: $skill_name"
done

# 2. Create ~/.proficiently/ data directory if it doesn't exist
mkdir -p ~/.proficiently/resume
mkdir -p ~/.proficiently/jobs

if [ ! -f ~/.proficiently/preferences.md ] && [ -f "$REPO_DIR/preferences.md" ]; then
  cp "$REPO_DIR/preferences.md" ~/.proficiently/preferences.md
  echo "    Copied preferences.md to ~/.proficiently/"
fi

if [ ! -f ~/.proficiently/application-data.md ]; then
  cat > ~/.proficiently/application-data.md << 'EOF'
# Application Data
# SINGLE SOURCE OF TRUTH — Fill in your details below.

## File Paths
- Resume PDF: ~/.proficiently/resume/your-resume.pdf

## Personal Information
- First Name:
- Last Name:
- Email:
- Phone:
- City:
- State:
- Postal Code:
- Address:
- Country: United States

## Online Profiles
- LinkedIn:
- GitHub:

## Standard Answers
- Authorized to work in the US: Yes
- Requires visa sponsorship: No

## Login Credentials
- Email:
- Password:
EOF
  echo "    Created ~/.proficiently/application-data.md (fill in your details)"
fi

if [ ! -f ~/.proficiently/job-history.md ]; then
  echo "# Job Application History" > ~/.proficiently/job-history.md
  echo "    Created ~/.proficiently/job-history.md"
fi

# 3. Install the auto-sync hook (optional — syncs skill edits back to this repo)
HOOK_SCRIPT="$HOME/claude-skills-autopush.sh"
cat > "$HOOK_SCRIPT" << HOOK
#!/bin/bash
# Auto-sync proficiently skills to git and push
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
echo "    Installed auto-sync hook: $HOOK_SCRIPT"

echo ""
echo "==> Done! Skills installed to ~/.claude/skills/proficiently/"
echo ""
echo "Next steps:"
echo "  1. Copy your resume PDF to ~/.proficiently/resume/"
echo "  2. Fill in ~/.proficiently/application-data.md with your details"
echo "  3. Fill in ~/.proficiently/preferences.md with your job search preferences"
echo "  4. Start with: /job-search or /apply <url>"
