#!/usr/bin/env bash
set -euo pipefail

# Run from ~/drawing. Creates standardgalactic/drawing as a public repository.
repo='standardgalactic/drawing'
root="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$root"

command -v git >/dev/null || { echo 'git is required' >&2; exit 1; }
command -v gh >/dev/null || { echo 'GitHub CLI (gh) is required' >&2; exit 1; }
gh auth status >/dev/null || { echo 'Sign in first: gh auth login' >&2; exit 1; }
if gh repo view "$repo" >/dev/null 2>&1; then
  echo "$repo already exists; refusing to create or overwrite it." >&2
  exit 1
fi
if [[ -e README.md || -e index.html ]]; then
  echo 'README.md or index.html already exists; review it before running this script.' >&2
  exit 1
fi
if [[ -d .git ]] && [[ -n "$(git remote)" ]]; then
  echo 'This directory already has a Git remote; refusing to change it.' >&2
  exit 1
fi

cat > README.md <<'EOF'
# Drawing and thought

Research and experiments on the order in which drawings are made, the development of graphic representation, and the use of drawing to think. The essays and figures here are separate works and should be read with their own citations and stated limits.

**Essays:** [Making Thought Visible](making_thought_visible.pdf) ([LaTeX source](making_thought_visible.tex)); [Architectures of Visual Abstraction](Architectures_of_Visual_Abstraction.pdf). The `figs/` directory holds supporting figures. [How Drawing Makes Thought Visible](How_Drawing_Makes_Thought_Visible.txt) also has [audio](How_Drawing_Makes_Thought_Visible.mp3) and [captions](How_Drawing_Makes_Thought_Visible.vtt). A [visual summary](drawing-infographic.png) is included.

![](drawing-infographic.png)

**Personal archive:** [Childhood drawings and older artwork](https://github.com/standardgalactic/archive). These are records of one person's drawing history, not a representative sample of children.

**Interactive study:** [Drawing order](index.html) lets you reorder the same marks and share the sequence in a URL. It is a conceptual demonstration, not data from a developmental study.
EOF

cat > index.html <<'EOF'
<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1">
<title>Drawing order</title>
<style>
  :root { color-scheme: dark light; font: 16px/1.5 system-ui,sans-serif; }
  body { max-width: 850px; margin: auto; padding: 1.5rem; }
  button { font: inherit; margin: .3rem .3rem .3rem 0; padding: .35rem .65rem; }
  svg { display: block; width: 100%; max-width: 620px; background: #faf8f0; border: 1px solid #888; }
  .mark { fill: none; stroke: #282529; stroke-width: 4; stroke-linecap: round; stroke-linejoin: round; }
  .active { stroke: #c34c32; stroke-width: 6; }
  #sequence { font-variant-numeric: tabular-nums; }
</style>
</head>
<body>
<h1>Drawing order</h1>
<p>The same four marks can be drawn in different orders. Select a sequence, then step through it. The URL records the order and current step, so another reader can see the same construction.</p>
<div id="choices" role="group" aria-label="Drawing orders"></div>
<svg viewBox="0 0 600 390" role="img" aria-label="Drawing constructed one mark at a time">
  <path id="a" class="mark" d="M115 180 Q300 45 485 180"/>
  <path id="b" class="mark" d="M115 180 Q300 330 485 180"/>
  <path id="c" class="mark" d="M300 70 L300 295"/>
  <path id="d" class="mark" d="M190 185 Q300 105 410 185"/>
</svg>
<p id="sequence" aria-live="polite"></p>
<button id="back" type="button">Previous mark</button><button id="next" type="button">Next mark</button>
<button id="copy" type="button">Copy this view's URL</button>
<p>This is a small experiment in construction sequence, not a model of how children draw. The resulting geometry is held constant so that only the order of inscription changes.</p>
<p><a href="making_thought_visible.pdf">Read the essay</a> · <a href="https://github.com/standardgalactic/archive">Visit the old art archive</a></p>
<script>
const orders = { outline: ['a','b','c','d'], axis: ['c','d','a','b'], upper: ['d','a','c','b'] };
const names = { outline: 'Outline first', axis: 'Axis first', upper: 'Upper curve first' };
const params = new URLSearchParams(location.search);
let order = Object.hasOwn(orders, params.get('order')) ? params.get('order') : 'outline';
let step = Number(params.get('step'));
step = Number.isInteger(step) ? Math.max(0, Math.min(4, step)) : 0;
const choices = document.getElementById('choices');
for (const key of Object.keys(orders)) {
  const button = document.createElement('button');
  button.type = 'button'; button.textContent = names[key];
  button.onclick = () => { order = key; step = 0; draw(); };
  button.dataset.order = key; choices.append(button);
}
function draw() {
  for (const id of ['a','b','c','d']) {
    const el = document.getElementById(id);
    const position = orders[order].indexOf(id);
    el.style.display = position < step ? '' : 'none';
    el.classList.toggle('active', position === step - 1);
  }
  for (const button of choices.children) button.setAttribute('aria-pressed', button.dataset.order === order);
  document.getElementById('sequence').textContent = `${names[order]}: ${step} of 4 marks`;
  document.getElementById('back').disabled = step === 0;
  document.getElementById('next').disabled = step === 4;
  const url = new URL(location.href);
  url.searchParams.set('order', order); url.searchParams.set('step', String(step));
  history.replaceState(null, '', url);
}
document.getElementById('back').onclick = () => { step--; draw(); };
document.getElementById('next').onclick = () => { step++; draw(); };
document.getElementById('copy').onclick = async () => {
  try { await navigator.clipboard.writeText(location.href); document.getElementById('copy').textContent = 'Copied'; }
  catch { window.prompt('Copy this URL:', location.href); }
};
draw();
</script>
</body>
</html>
EOF

if [[ ! -d .git ]]; then git init -b main; fi
git add -A
echo 'Files that will be committed:'
git diff --cached --stat
git diff --cached --check
if git diff --cached --quiet; then echo 'Nothing to commit.' >&2; exit 1; fi
git commit -m 'Drawing sequence'
gh repo create "$repo" --public --source . --remote origin
git push -u origin HEAD:main
echo "Repository: https://github.com/$repo"
echo "To enable the experiment: Settings → Pages → Deploy from a branch → main / (root)."

