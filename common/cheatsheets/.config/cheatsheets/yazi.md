# Yazi cheat sheet

Three columns: parent | current | preview. Keys are case-sensitive.
Press `F1` or `~` inside yazi for the full list. `q` closes this sheet, `/` searches it.

## Moving around

| Key | Action |
|---|---|
| `h` / `l` | go to parent / enter directory (or open file) |
| `j` / `k` | down / up |
| `gg` / `G` | top / bottom of the list |
| `Ctrl-d` / `Ctrl-u` | half page down / up |
| `H` / `L` | back / forward in history |
| `J` / `K` | scroll the preview down / up |
| `gh` | go to home |
| `gc` | go to config dir (~/.config) |
| `gd` | go to Downloads |
| `g Space` | type a path and jump to it |
| `z` | jump to a file or dir with fzf (fuzzy find) |
| `Z` | jump to a recent dir with zoxide |
| `gt` | go to the trash bin |
| `gf` | follow the symlink under the cursor |

## Opening files

| Key | Action |
|---|---|
| `Enter` / `o` | open with the default program |
| `O` | choose which program opens it |
| `Tab` | file info (spot) |

## Selecting

| Key | Action |
|---|---|
| `Space` | select / unselect, then move down |
| `v` | visual mode: select a range with `j`/`k` |
| `V` | visual mode that unselects |
| `Ctrl-a` | select all |
| `Ctrl-r` | invert selection |
| `Esc` | clear selection / cancel |

Every file operation below acts on the selection, or on the file under the
cursor when nothing is selected.

## File operations

| Key | Action |
|---|---|
| `y` | yank (copy) |
| `x` | cut |
| `p` | paste |
| `P` | paste, overwriting files with the same name |
| `Y` / `X` | cancel yank / cut |
| `d` | move to trash |
| `D` | delete permanently |
| `a` | create file (end the name with `/` for a directory) |
| `A` | create several files at once |
| `r` | rename (with a selection: bulk rename in $EDITOR) |
| `-` | create absolute symlink to the yanked files |
| `_` | create relative symlink to the yanked files |
| `.` | show / hide hidden files |

## Copy paths to the clipboard

| Key | Action |
|---|---|
| `cc` | full path |
| `cd` | directory |
| `cf` | file name |
| `cn` | file name without extension |

## Finding things

| Key | Action |
|---|---|
| `/` / `?` | find next / previous match in this directory |
| `n` / `N` | next / previous match |
| `f` | filter the list as you type |
| `s` | search file names recursively (fd) |
| `S` | search file contents recursively (rg) |
| `Ctrl-s` | cancel the search |

## Sorting and columns

| Key | Action |
|---|---|
| `,m` / `,M` | sort by modified time (newest first with `M`) |
| `,a` / `,A` | sort alphabetically / reversed |
| `,n` | natural sort (file2 before file10) |
| `,s` / `,S` | sort by size / reversed |
| `,e` | sort by extension |
| `ms` | show size column |
| `mm` | show modified time column |
| `mp` | show permissions column |
| `mn` | hide extra column |

## Tabs

| Key | Action |
|---|---|
| `tt` | new tab in the current directory |
| `tr` | rename the tab |
| `1` … `9` | switch to tab N |
| `[` / `]` | previous / next tab |
| `{` / `}` | move the tab left / right |
| `Ctrl-c` | close tab (quits yazi if it is the last) |

## Shell and misc

| Key | Action |
|---|---|
| `;` | run a shell command (in background) |
| `:` | run a shell command and wait (blocking) |
| `w` | task manager (copies, deletes in progress) |
| `Ctrl-z` | suspend yazi, back to the shell (`fg` to return) |
| `q` | quit |
| `F1` / `~` | help: every key, searchable |
