# Neovim

`<Space>` is the leader key.

## Custom Binds

## General

| Keys | What it does |
|---|---|
| `<Space>w` | Save the file. |
| `<Space>q` | Quit the current window. |
| `<Space>nh` | Clear search highlights. | 
| `<Space>?` | Show keymaps for the current buffer. |
| `<Space>ee` | Toggle the File Explorer. |

## Windows

| Keys | What it does |
|---|---|
| `<Space>sv` | Split the window vertically. |
| `<Space>sh` | Split the window horizontally. |
| `<Ctrl>h` | Move to the left window. |
| `<Ctrl>j` | Move to the lower window. |
| `<Ctrl>k` | Move to the upper window. |
| `<Ctrl>l` | Move to the right window. |

## Indenting

| Keys | What it does |
|---|---|
| `<Tab>` (normal) | Indent the current line. |
| `<Shift>+<Tab>` (normal) | Outdent the current line. |
| `<Shift>+<Tab>` (insert) | Outdent the current line while typing. |
| `<Tab>` (visual) | Indent the selection and keep it selected. |
| `<Shift>+<Tab>` (visual) | Outdent the selection and keep it selected. |

## Telescope (Search)

| Keys | What it does|
|---|---|
| `<Space>ff` | Find files by name. |
| `<Space>fg` | Search text across the project. |
| `<Space>fb` | Switch between open buffers. |

## LSP (Code Intelligence)

| Keys | What it does |
|---|---|
| `gd` | Go to the definition. |
| `gD` | Go to the decleration.
| `K` | Show hover documentation. | 
| `<Space>ca` | Show code actions. |
| `<Space>rn` | Rename the symbol under the cursor. |

## Trouble (Code Diagnostics)

| Keys | What it does |
|---|---|
| `<Space>xx` | Toggle the diagnostics for the project. |
| `<Space>xX` | Toggle diagnostics for this buffer. |
| `<Space>cs` | Toggle the symbols list. |
| `<Space>cl` | Toggle LSP definitions and references. | 
| `<Space>xL` | Toggle the location list. |
| `<Space>xQ` | Toggle the quickfix list. |

## Git

| Keys | What it does |
|---|---|
| `<Space>gs` | Open git status (Fugitive). |
| `<Space>gb` | Show git blame for the file. |
| `<Space>gd` | Open a diff split. |
| `<Space>gp` | Git push. |
| `<Space>gl` | Git pull. |
| `]c` | Jump to the next changed hunk. |
| `[c` | Jump to the previous changed hunk. |
| `<Space>hp` | Preview the current hunk. |
| `<Space>hb` | Show blame for the current line. |

## Autocomplete (blink.cmp)

 Keys | What it does |
|---|---|
| `<Ctrl>Space` | Open the completion menu or docs. |
| `<Ctrl>n` | Select the next item. |
| `<Ctrl>p` | Select the previous item. |
| `<Ctrl>y` | Accept the selected item. |
| `<Ctrl>e` | Close the completion menu. |
| `<Ctrl>b` | Scroll docs up. |
| `<Ctrl>f` | Scroll docs down. |
| `<Ctrl>k` | Show signature help. |
| `<Tab>` | Jump to the next snippet field. |
| `<Shift>+<Tab>` | Jump to the previous snippet field. |

## Autopairs
 
| Keys | What it does |
|---|---|
| `<Alt>e` | Fast wrap the next text in a pair like `()` or `""`. |
 
## Dashboard (Start Screen)
 
| Keys | What it does |
|---|---|
| `f` | Find a file. |
| `g` | Live grep. |
| `r` | Open a recent file. |
| `n` | Create a new file. |
| `c` | Browse the Neovim config. |
| `l` | Open Lazy. |
| `m` | Open Mason. |
| `q` | Quit Neovim. |


## Basic Binds

## Modes

| Keys | What it does |
|---|---|
| `<Esc>` | Return to normal mode. |
| `i` | Insert before the cursor. |
| `a` | Insert after the cursor. |
| `I` | Insert at the start of the line. |
| `A` | Insert at the end of the line. |
| `o` | Open a new line below. |
| `O` | Open a new line above. |
| `v` | Start character-wise visual mode. |
| `V` | Start line-wise visual mode. |
| `<Ctrl>v` | Start block visual mode. |
| `:` | Enter command mode. |

## Movement

| Keys | What it does |
|---|---|
| `h` `j` `k` `l` | Move left, down, up, right. |
| `w` | Jump to the start of the next word. |
| `b` | Jump to the start of the previous word. |
| `e` | Jump to the end of the word. |
| `0` | Go to the start of the line. |
| `^` | Go to the first non-blank character. |
| `$` | Go to the end of the line. |
| `gg` | Go to the first line of the file. |
| `G` | Go to the last line of the file. |
| `5G` | Go to line 5. |
| `5j` | Move down 5 lines (handy with relative numbers). |
| `%` | Jump to the matching bracket. |
| `{` | Jump to the previous blank line. |
| `}` | Jump to the next blank line. |
| `f` + char | Jump to the next occurrence of a character on the line. |
| `t` + char | Jump to just before that character. |
| `;` | Repeat the last `f` or `t` forward. |
| `,` | Repeat the last `f` or `t` backward. |
| `<Ctrl>o` | Jump back in the jump list. |
| `<Ctrl>i` | Jump forward in the jump list. |

## Editing
 
| Keys | What it does |
|---|---|
| `x` | Delete the character under the cursor. |
| `dd` | Delete the current line. |
| `D` | Delete from the cursor to the end of the line. |
| `dw` | Delete to the start of the next word. |
| `cw` | Change the word under the cursor. |
| `cc` | Change the whole line. |
| `C` | Change from the cursor to the end of the line. |
| `r` + char | Replace one character. |
| `yy` | Copy the current line. |
| `yw` | Copy a word. |
| `p` | Paste after the cursor. |
| `P` | Paste before the cursor. |
| `u` | Undo. |
| `<Ctrl>r` | Redo. |
| `.` | Repeat the last change. |
| `J` | Join the next line onto this one. |
| `>>` | Indent the line. |
| `<<` | Outdent the line. |
| `~` | Toggle the case of a character. |
 
## Text Objects
 
Combine these with `d`, `c`, `y`, or `v`. For example, `ciw` changes the word under the cursor.
 
| Keys | What it does |
|---|---|
| `iw` | Inner word. |
| `aw` | A word including the surrounding space. |
| `i"` | Inside double quotes. |
| `a"` | Around double quotes, including the quotes. |
| `i(` | Inside parentheses. |
| `a(` | Around parentheses, including them. |
| `i{` | Inside curly braces. |
| `ip` | Inner paragraph. |
 
## Visual Mode
 
| Keys | What it does |
|---|---|
| `d` | Delete the selection. |
| `y` | Copy the selection. |
| `c` | Change the selection. |
| `>` | Indent the selection. |
| `<` | Outdent the selection. |
| `u` | Lowercase the selection. |
| `U` | Uppercase the selection. |
| `o` | Jump to the other end of the selection. |
| `gv` | Reselect the last selection. |
 
## Search and Replace
 
| Keys | What it does |
|---|---|
| `/text` | Search forward for text. |
| `?text` | Search backward for text. |
| `n` | Go to the next match. |
| `N` | Go to the previous match. |
| `*` | Search for the word under the cursor. |
| `#` | Search backward for the word under the cursor. |
| `:%s/old/new/g` | Replace all matches in the file. |
| `:%s/old/new/gc` | Replace all matches and confirm each one. |
| `:s/old/new/` | Replace on the current line. |
 
## Files and Buffers
 
| Keys | What it does |
|---|---|
| `:w` | Save the file. |
| `:q` | Quit the window. |
| `:wq` | Save and quit. |
| `:q!` | Quit without saving. |
| `:qa` | Quit everything. |
| `:e file` | Open a file. |
| `:ls` | List open buffers. |
| `:bn` | Go to the next buffer. |
| `:bp` | Go to the previous buffer. |
| `:bd` | Close the current buffer. |
 
## Windows
 
| Keys | What it does |
|---|---|
| `<Ctrl>w` `v` | Split vertically. |
| `<Ctrl>w` `s` | Split horizontally. |
| `<Ctrl>w` `w` | Cycle through windows. |
| `<Ctrl>w` `c` | Close the current window. |
| `<Ctrl>w` `o` | Close all other windows. |
| `<Ctrl>w` `=` | Make all windows equal size. |
 
## Folds
 
| Keys | What it does |
|---|---|
| `za` | Toggle the fold under the cursor. |
| `zc` | Close the fold. |
| `zo` | Open the fold. |
| `zR` | Open all folds. |
| `zM` | Close all folds. |
 
## Spell Check (Markdown, text, git commits)
 
| Keys | What it does |
|---|---|
| `]s` | Jump to the next misspelled word. |
| `[s` | Jump to the previous misspelled word. |
| `z=` | Show spelling suggestions. |
| `zg` | Add the word to the dictionary. |
| `zw` | Mark the word as misspelled. |
 
## Macros and Registers
 
| Keys | What it does |
|---|---|
| `q` + letter | Start recording a macro. |
| `q` | Stop recording. |
| `@` + letter | Play a macro. |
| `@@` | Replay the last macro. |
| `"ayy` | Copy a line into register `a`. |
| `"ap` | Paste from register `a`. |
 
## Lazy.nvim and Mason
 
| Command | What it does |
|---|---|
| `:Lazy` | Open the plugin manager. |
| `:Mason` | Open the LSP and tool installer. |

