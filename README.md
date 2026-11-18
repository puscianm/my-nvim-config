# My neovim config
Based on NvChad distro

## Live grep (`<leader>fw`)

Searches the project with ripgrep. What you type is a **regex**. To add
ripgrep options, the search term must be quoted: `"np.linalg.norm" -t py`.
`<C-k>` (quote), `<C-f>` (quote + `-F`) and `<C-i>` (quote + `--iglob `) add
the quotes for you. `<C-Space>` switches to filtering the results you already
have.

### Regex (default) vs literal (`<C-f>`)

Plain names and words behave the same either way. The difference is in regex
symbols: `. ( ) [ ] * + ? | ^ $ \`.

| You type | As regex (default) | With `<C-f>` (literal) |
|---|---|---|
| `n_components=` | finds it | finds it (no special characters, same result) |
| `np.linalg.norm(` | **nothing**: regex error, `(` opens a group that's never closed | finds it |
| `**kwargs` | **nothing**: regex error, `*` needs something before it | finds it |
| `x.T` | **false matches**: `.` matches any character (`xxT`, `x_T`, ...) | only the text `x.T` |

A regex error shows up as an empty result list, with no message. If a search
that should find something comes back empty, try `<C-f>`.

### Filtering results (`<C-Space>`)

After `<C-Space>` the prompt filters the current results with fzf syntax.
The live grep keys (`<C-k>`, `<C-f>`, `<C-i>`) don't work here.

| In the refine prompt | Means |
|---|---|
| `src` | fuzzy: s…r…c in that order, anywhere in the line |
| `'src` | exact: the text `src` must appear |
| `^src` | line starts with `src` (for grep results, the filename starts with it) |
| `.py$` | line ends with `.py` |
| `!test` | exclude lines containing `test` |
| `'src !test` | both: spaces mean AND |
| `src \| scripts` | either one (OR) |
