# claude-skills

Personal Claude Code skills, symlinked into `~/.claude/skills/` so they are
available user-wide in every project.

## Skills

- **app-store-screenshots** — build localized App Store screenshot sets from real
  device captures with a programmatic Pillow compositor (`compositor_template.py`
  is the per-project starting point). Never lets image-AI redraw UI text.
- **aso** — App Store Optimization audit: name/subtitle/keywords per storefront
  locale with hard character limits, promoted IAP, conversion copy.

## Install (new machine)

```bash
for s in app-store-screenshots aso; do
  ln -s ~/Projects/claude-skills/$s ~/.claude/skills/$s
done
```
