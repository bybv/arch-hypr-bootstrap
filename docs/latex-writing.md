# LaTeX writing with Tectonic

Reference for the `writing` app role (`pkglists/apps-writing.txt`, installed via
`./bootstrap-apps.sh writing`). Goal: gorgeous, flexible **non-math** documents.

## Engine note

Tectonic is **XeTeX-based**, so it is UTF-8 native and can use any installed
system font via `fontspec`. It also runs all needed compile passes automatically
(no `latexmk`) — just `tectonic doc.tex`.

## Tectonic & packages

Tectonic **auto-downloads** all needed LaTeX packages (KOMA-Script, microtype,
booktabs, hyperref, …) on first compile from its own bundle. You do **not**
pacman-install `texlive-*`. The only things that must be real Arch packages are
**fonts**, because `fontspec` pulls fonts from the OS — that is all
`apps-writing.txt` provides.

## Document class (biggest single lever — replaces stock article/report)

- **KOMA-Script** — `scrartcl` (articles), `scrreprt` (reports), `scrbook`
  (books), `scrlttr2` (letters). Beautiful European defaults, clean control over
  headings/margins/fonts. **The default recommendation.**
- **memoir** — alternative for long/book-length docs; enormous built-in control
  if you want one class that does everything.

## Fonts (the look)

`fontspec` provides `\setmainfont{...}`, `\setsansfont{...}`,
`\setmonofont{...}` to use any system font. Good free choices:

| Font | Availability |
|------|--------------|
| Libertinus (excellent all-rounder) | ships in `apps-writing.txt` (`otf-libertinus`) |
| Source Serif / Source Sans | ships in `apps-writing.txt` (`adobe-source-serif-fonts`, `adobe-source-sans-fonts`) |
| EB Garamond | AUR-only (`otf-ebgaramond`) — install manually if wanted |
| New Computer Modern (modern, prettier Computer Modern) | AUR-only (`otf-new-computer-modern`) — install manually if wanted |

## Paper size & margins ("different sizes")

- **geometry** — e.g. `\usepackage[a4paper,margin=2.5cm]{geometry}`, or
  `letterpaper`, or fully custom `paperwidth`/`paperheight`. Main page-sizing
  control.
- KOMA also takes class options like `paper=a5`, `fontsize=11pt`.

## Typographic polish

- **microtype** — character protrusion + font expansion. **Caveat: under XeTeX
  (Tectonic's engine) you get protrusion only; font expansion needs pdfTeX or
  LuaTeX.** Still always include it.
- **setspace** — line spacing (`\onehalfspacing`, etc.).
- **parskip** (or KOMA's `parskip=half`) — blank-line paragraph spacing instead
  of indents, if you prefer that look.
- **csquotes** — proper curly/contextual quotation marks (`\enquote{...}`).

## Structure & elements

- **enumitem** — fine control over list spacing/labels.
- **booktabs** — genuinely beautiful tables (`\toprule`/`\midrule`/
  `\bottomrule`); avoid vertical rules.
- **graphicx** — include images (`\includegraphics`).
- **xcolor** — color.
- **hyperref** — clickable links + sets PDF metadata/bookmarks; **load it last**.
- **scrlayer-scrpage** (KOMA) or **fancyhdr** — custom headers/footers.
- **titlesec** — restyle section headings (or use KOMA's built-in heading
  options).

## Sensible starting stack (clean article)

`scrartcl` + `fontspec` (a nice serif) + `geometry` + `microtype` + `csquotes` +
`booktabs` + `hyperref`.

## Minimal example

```latex
\documentclass[a4paper,11pt]{scrartcl}
\usepackage{fontspec}
\setmainfont{Libertinus Serif}
\usepackage[margin=2.5cm]{geometry}
\usepackage{microtype}
\usepackage{csquotes}
\usepackage{booktabs}
\usepackage{hyperref} % load last

\title{A Clean Document}
\author{Me}

\begin{document}
\maketitle
\section{Introduction}
\enquote{Hello, world.} This compiles with \texttt{tectonic doc.tex}.
\end{document}
```
