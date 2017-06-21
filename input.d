
class InputHandler {


    private {
        string[] hist;
    }

    final string getstr(){
        // C input items
        import std.stdio: write;
        import core.sys.posix.termios: termios, tcsetattr, tcgetattr, ICANON, TCSANOW, ECHO;
        import core.stdc.stdio: getchar;

        char ch;
        termios oldt;
        termios newt;
        string buffer;
        ulong cursor;
        ulong tabCounter = 0;
        ulong histIdx = hist.length;

        // Get terminal attributes
        tcgetattr(0, &oldt);
        // Copy for new options
        newt = oldt;
        // Set flags to non-canonical input
        newt.c_lflag &= ~(ICANON | ECHO);
        // Set new attributes
        tcsetattr(0, TCSANOW, &newt);
        // Keep getting characters until newline
        while((ch = cast(char) getchar()) != '\n') {
            switch(ch) {
                case 127: // bksp
                case 8:
                    bksp(buffer, cursor);
                    tabCounter = 0;
                    break;
                case '\t': // tab
                    tab(tabCounter, buffer, cursor);
                    break;
                case '\033': // '\'
                    getchar(); // eat the '['
                    switch (ch = cast(char) getchar()) {
                        case 65: // up
                            up(buffer, cursor, histIdx);
                            continue;
                        case 66: // down
                            down(buffer, cursor, histIdx);
                            continue;
                        case 67: // right
                            cursorRight(buffer, cursor);
                            continue;
                        case 68: // left
                            cursorLeft(cursor);
                            continue;
                        default:
                            break;
                    }
                    tabCounter = 0;
                    break;
                default:
                    inst(buffer, cursor, ch);
                    tabCounter = 0;
            }
        }

        // Add the command to the history
        if (buffer != "")
            hist ~= buffer;

        // Reset attributes
        tcsetattr(0, TCSANOW, &oldt);

        write("\n");

        return buffer;
    }

    /**
     * Gets the previous command in the history list
     */
    private string prevCmd(ref ulong idx) {
        if (idx > 0) {
            idx--;
        }
        return hist.length != 0 ? hist[idx] : "";
    }

    /**
     * Gets the next command in the history list
     */
    private string nextCmd(ref ulong idx) {
        if (idx < hist.length) {
            idx++;
        }
        return (idx == hist.length || hist.length == 0) ? "" : hist[idx];
    }

    /**
     * Sets the buffer and display to the given string 'str'
     */
    private void setBuffer(ref string buffer, ref ulong cursor, string str) {
        import std.stdio: write;

        clearInput(buffer, cursor);
        buffer = str;
        cursor = str.length;
        write(buffer);
    }

    /**
     * Clears the display's current input
     */
    private void clearInput(ref string buffer, ref ulong cursor) {
        import std.stdio: write;

        while (cursor < buffer.length) {
            write(' ');
        }
        while (cursor-- > 0) {
            write("\b \b");
        }
    }

    /**
     * Moves the cursor right one position
     */
    private void cursorRight(ref string buffer, ref ulong cursor) {
        import std.stdio: write;

        if (cursor < buffer.length) {
            write(buffer[cursor]);
            cursor++;
        }
    }

    /**
     * Moves the cursor left one position
     */
    private void cursorLeft(ref ulong cursor) {
        import std.stdio: write;

        if (cursor > 0) {
            write('\b');
            cursor--;
        }
    }

    /**
     * Inserts a character at the position given by cursor into
     * buffer
     */
    private void inst(ref string buffer, ref ulong cursor, char ch) {
        import std.stdio: write;

        if (cursor == 0) {
            // Inserting at the beginning
            write(ch, buffer);
            buffer = ch ~ buffer;
            cursor++;
        } else if (cursor == buffer.length) {
            // Inserting at the end
            write(ch);
            buffer ~= ch;
            cursor++;
        } else {
            // Inserting in the middle
            buffer = buffer[0 .. cursor] ~ ch ~ buffer[cursor .. $];
            write(ch, buffer[++cursor .. $]);
            for (ulong i = buffer.length; i > cursor; i--) {
                write('\b');
            }
        }
    }

    /**
     * Prints removes the character at the position given
     * by the cursor from the buffer and on the display
     */
    private void bksp(ref string buffer, ref ulong cursor) {
        import std.stdio: write;

        // Don't backspace if at the beginning, or empty
        if (buffer.length != 0 && cursor > 0) {
            if (cursor == buffer.length) {
                // Backspace at the end
                write("\b \b");
                buffer = buffer[0 .. $-1];
            } else {
                // In the middle
                write('\b', buffer[cursor .. $], " ");
                buffer = buffer[0 .. cursor-1] ~ buffer[cursor .. $];
                foreach (i ; 0 .. (buffer.length - cursor)+2) {
                    write('\b');
                }
            }
            cursor--;
        }
    }

    /**
     * Handle the up arrow key
     */
    private void up(ref string buffer, ref ulong cursor, ref ulong histIdx) {
        setBuffer(buffer, cursor, prevCmd(histIdx));
    }

    /**
     * Handle the down arrow key
     */
    private void down(ref string buffer, ref ulong cursor, ref ulong histIdx) {
        setBuffer(buffer, cursor, nextCmd(histIdx));
    }

    /**
     * Handle the tab key
     */
    private void tab(ref ulong tabCounter, ref string buffer, ref ulong cursor) {
        import std.stdio: writef, write;
        import std.array: split, join, replicate;
        import std.string: strip;
        import std.path: isValidPath;

        // Get the auto-completed string and set it.
        string[] args = split(buffer);
        if (args.length > 0 && isValidPath(args[$-1])) {
            args[$-1] ~= autoComplete(strip(args[$-1]));
            setBuffer(buffer, cursor, join(args, " "));
        }

        // Print the file path at the correct directory if tab pressed
        // more than once consecutively
        if (tabCounter++ > 0) {
            string[] files;
            if (args.length > 0) {
                files = filesStartingWith(args[$-1], filename(args[$-1]));
            } else {
                files = getFilesInDir("./");
            }
            if (files.length > 0) {
                write("\n");
                ulong maxLen = 0;
                foreach (file; files) if (file.length > maxLen) maxLen = file.length;

                for (ulong i = 0; i < files.length; i++) {
                    writef("%s%s%s",filename(files[i]),
                                    replicate(" ", maxLen-files[i].length),
                                    (i % 5 == 4 && i != files.length-1) ? "\n" : "  ");
                }
                write("\n");
                write(">| ", buffer);
            }
        }
    }

    /**
     * Returns the string needed to complete 'path' in such a way
     * that it will match a file in the system. 
     */
    private string autoComplete(string path = ""){
        // Get the suggested autocomplete addition
        string filename = filename(path);
        string completion = completion(path, filesStartingWith(path, filename), filename);

        // Add a '/' if the completed file is a directory

        return completion;
    }

    /**
     * Gets the filenames of all files in the
     * directory at the given path
     */
    string[] getFilesInDir(string path) {
        import std.array: array;
        import std.path: dirName, dirEntries, SpanMode;

        string dir = path;
        string base = filename(path);
        string[] files;

        // Try using the given path
        try {
            auto f = array(dirEntries(dir, "*", SpanMode.shallow));
            foreach (file; f) files ~= filename(file);
        } catch (Exception ex) {
            // If path is broken, use the previous one
            dir = getPath(path);
            auto f = array(dirEntries(dir, "*", SpanMode.shallow));
            foreach (file; f) files ~= filename(file);
        }
        return files;
    }

    /**
     * Returns a string that completes the given query so that the
     * returned value is the longest substring common to all of
     * the files passed in 
     */
    string completion(string path, string[] files, string query) {
        import std.stdio;
        import std.file: isDir, FileException;

        string completion = "";
        ulong min = ulong.max;

        // Get minimum length of a filename
        foreach (file; files) if (file.length < min) min = file.length;
        

        if (files.length == 0) return "";
        main_loop: for (ulong i = query.length; i < min; i++) {
            // Stop if there is a non-match
            foreach (file; files[1 .. $])
                if (file[i] != files[0][i]) break main_loop;
            
            // Add the next character on
            completion ~= files[0][i];
        }

        try {
            completion ~= ((files.length == 1 && isDir(path~completion) && path[$-1] != '/') ? "/" : "");
        } catch (FileException ex) {}

        return completion;
    }

    /**
     * Returns all files at the given path that start
     * with the given query string
     */
    string[] filesStartingWith(string path, string query) {
        string[] allFiles = getFilesInDir(getPath(path));
        string[] files = [];

        // Keep files that start with the query
        foreach (file; allFiles) {
            if (file.length >= query.length && file[0 .. query.length] == query) {
                files ~= file;
            }
        }
        return files;
    }

    /**
     * Gets only the path (no filename)
     */
    private string getPath(string path) {
        import std.string: lastIndexOf;
        if (path.length == 0) return "";
        return path[0..lastIndexOf(path, '/')+1];
    }

    /**
     * Pulls the filename off of a path
     */
    private string filename(string path) {
        import std.string: lastIndexOf;
        if (path.length == 0) return "";
        return path[lastIndexOf(path, '/')+1..$];
    }
}
