# Neovim + LazyVim cheat sheet

`Space` is the leader key. Press `Space` and wait: a menu (which-key) shows
every next key. `Space sk` searches all keymaps. `q` closes this sheet, `/` searches it.

## Modes: the one thing to get

| Key | Action |
|---|---|
| `Esc` | back to Normal mode (where keys are commands) |
| `i` / `a` | insert before / after the cursor |
| `I` / `A` | insert at start / end of the line |
| `o` / `O` | new line below / above and insert |
| `v` / `V` | select characters / whole lines (Visual) |
| `Ctrl-v` | select a block (columns) |
| `:` | command line (`:w`, `:q`, ...) |

## Save and quit

| Key | Action |
|---|---|
| `Ctrl-s` | save (works in any mode) |
| `:w` / `:q` / `:wq` | save / quit window / save and quit |
| `:q!` | quit, discard changes |
| `Space qq` | quit everything |
| `Space qs` | restore last session for this directory |

## Moving

| Key | Action |
|---|---|
| `h` `j` `k` `l` | left, down, up, right |
| `w` / `b` / `e` | next word / previous word / end of word |
| `0` / `^` / `$` | line start / first character / line end |
| `gg` / `G` | top / bottom of the file |
| `42G` or `:42` | go to line 42 |
| `Ctrl-d` / `Ctrl-u` | half page down / up |
| `%` | jump to the matching bracket |
| `f x` / `t x` | jump to / just before the next `x` on the line (`;` repeats) |
| `s` | flash: type 2 chars, then the label shown, to jump anywhere |
| `Ctrl-o` / `Ctrl-i` | jump back / forward (after `gd`, search, ...) |

## Editing

| Key | Action |
|---|---|
| `x` | delete character |
| `dd` / `yy` / `cc` | delete / copy (yank) / change a line |
| `p` / `P` | paste after / before |
| `u` / `Ctrl-r` | undo / redo |
| `.` | repeat the last change |
| `>>` / `<<` | indent / unindent (`>` / `<` in Visual) |
| `J` | join the line below to this one |
| `r x` | replace the character with `x` |
| `~` | toggle case |
| `gcc` | comment / uncomment line (`gc` in Visual) |
| `Alt-j` / `Alt-k` | move line (or selection) down / up |

## Verbs + motions (the grammar)

An operator followed by a motion or text object: `d` delete, `c` change,
`y` yank, `v` select, `gc` comment.

| Key | Action |
|---|---|
| `dw` / `d$` | delete to next word / to end of line |
| `ciw` | change inner word |
| `ci"` / `ca"` | change inside quotes / including the quotes |
| `di(` / `da{` | delete inside parens / around braces |
| `yap` | yank a paragraph |
| `vif` / `vaf` | select inside / around a function |
| `dit` | delete inside an HTML tag |
| `3dd` / `5j` | a count repeats: delete 3 lines, down 5 |

Text objects: `w` word, `p` paragraph, `"` `'` `` ` `` quotes, `(` `[` `{` `<`
brackets, `t` tag, `f` function, `c` class, `a` argument. `i` = inside, `a` = around.

## Search and replace

| Key | Action |
|---|---|
| `/text` / `?text` | search forward / backward, `Enter` to confirm |
| `n` / `N` | next / previous match |
| `*` | search the word under the cursor |
| `Esc` | clear search highlight |
| `:%s/old/new/g` | replace in the whole file (`/gc` asks each time) |
| `Space sr` | search and replace across the project |

## Finding files and text

| Key | Action |
|---|---|
| `Space Space` | find files in the project |
| `Space /` | grep the project for text |
| `Space ,` | open buffers (open files) |
| `Space fr` | recent files |
| `Space fc` | find a config file (nvim) |
| `Space sw` | grep the word under the cursor |
| `Space sb` | search lines in this file |
| `Space sh` | search help pages |
| `Space sk` | search keymaps |

Inside a picker: type to filter, `Ctrl-j` / `Ctrl-k` move, `Enter` opens,
`Ctrl-v` / `Ctrl-s` opens in a vertical / horizontal split, `Esc` closes.

## File explorer

| Key | Action |
|---|---|
| `Space e` | toggle the explorer (project root) |
| `Space E` | toggle the explorer (current directory) |
| `a` | (in explorer) new file, end with `/` for a directory |
| `r` / `d` | (in explorer) rename / delete |
| `y` / `p` | (in explorer) yank / paste files |
| `c` / `m` | (in explorer) copy / move to a path you type |
| `H` / `I` | (in explorer) show hidden / ignored files |
| `?` | (in explorer) all its keys |

## Buffers (open files) and windows (splits)

| Key | Action |
|---|---|
| `H` / `L` | previous / next buffer (the tabs at the top) |
| `Space bd` | close buffer |
| `Space bo` | close all other buffers |
| `Space bb` | switch to the last buffer |
| `Space -` / `Space \|` | split below / right |
| `Ctrl-h` `j` `k` `l` | move between windows |
| `Ctrl-Up/Down/Left/Right` | resize window |
| `Space wd` | close window |

## Code (when a language server is running)

| Key | Action |
|---|---|
| `gd` | go to definition |
| `gr` | list references |
| `K` | documentation popup (twice to enter it) |
| `Space ca` | code action (quick fixes, imports) |
| `Space cr` | rename symbol everywhere |
| `Space cf` | format file |
| `]d` / `[d` | next / previous diagnostic |
| `Space cd` | show the diagnostic on this line |
| `Space xx` | all diagnostics (Trouble) |
| `Space cm` | Mason: install language servers / formatters |

Completion menu: `Ctrl-n` / `Ctrl-p` move, `Enter` accepts,
`Ctrl-Space` opens it, `Ctrl-e` closes it.

## Git

| Key | Action |
|---|---|
| `Space gg` | lazygit |
| `]h` / `[h` | next / previous changed hunk |
| `Space ghp` | preview the hunk |
| `Space ghs` / `Space ghr` | stage / reset the hunk |
| `Space gb` | blame this line |

## Terminal and misc

| Key | Action |
|---|---|
| `Ctrl-/` | toggle a floating terminal |
| `Space l` | Lazy: update and manage plugins |
| `Space uC` | pick a colorscheme |
| `Space uw` | toggle line wrap |
| `Space n` | notification history |
| `:checkhealth` | diagnose problems |
| `:Tutor` | 30-minute interactive vim lesson |
