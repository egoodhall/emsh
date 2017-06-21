# EMShell
---

Eric Marshall

### Usage
1. Make sure the D language is enabled (on the lab machines, run `module load csci208/langs`)
2. Run makefile with `make`
3. Run the shell with `./emsh`

### What is EMShell?
EMShell is a command line shell that is designed to work similarly to the Bash shell. The EMShell supports the `cd` command, `tab` to autocomplete directory names, `exit`, as well as running other command line programs. The left and right arrow keys can be used to move the cursor, and backspace can be used to remove characters, either from the end or in the middle of the string. The up and down arrow keys support a session command history, with up being the previous command in the list and down being the next one.

### Why a shell in D?
D is built to be a concise language that allows for high-level programming while still being very low overhead. One of its abilities is to be able to use C libraries directly. In order to get much of the functionality of the shell's input, we need to use noncanonical input (read character-by-character instead of dumping the entire line on a newline being entered), which is only possible using C APIs. This makes D perfect for building a shell, because it allows for sophistocated string manipulation functions while still giving access to the low-level API's when needed.

### NOTE ABOUT CRASHES:
The shell is NOT perfect! There are still some bugs, and if it crashes while collecting input from the user, there is a chance that your terminal session will be left in noncanonical mode. To fix this, the only solution is to close that shell and open a new one!

### Shell Features:

- [x] `cd [path]` - Change the directory to the one specified by `path` - Note: `~` expansion is buggy - relative paths and absolute paths should work
- [x] `exit` - Exit the shell
- [x] `tab` - Tab will present autocomplete suggestions and complete filenames when entering paths - Note: still buggy
- [x] `arrow keys/backspace` - The arrow keys and backspace allow for editing input lines and traversing through the command history for the session.