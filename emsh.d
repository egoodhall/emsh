import std.file: chdir;
import std.path: absolutePath;
import std.process: spawnProcess, wait, ProcessException;
import std.stdio: write, StdioException;
import std.string: munch, strip, split;
import input: InputHandler;

/**
 * Runs the EMSHell
 */
void main() {
    // Used for getting and handling input
    auto inhd = new InputHandler();
    string cmd;
    string prog;
    while (true) {
        write(">| ");
        
        cmd = inhd.getstr();
        prog = munch(cmd, "^ ");

        if (prog == "exit") {
            // Exit
            return;
        } else if (prog == "cd") {
            import std.file: FileException;
            // Change directories
            try {
                chdir(absolutePath(strip(cmd)));
            } catch (FileException ex) {
                write(ex.msg, "\n");
            }
        } else if (prog == "") {
            continue;
        } else {
            // Execute the command
            execCmd(prog~" "~cmd);
        }
    }
}

/**
 * Attempt to execute a program given by cmd
 */
private void execCmd(string cmd) {
    try {
        wait(spawnProcess(split(cmd)));
    } catch (ProcessException ex) {
        write("Process launch failed: ", ex.msg, "\n");
    } catch (StdioException ex) {
        write("Error in Input/Output: ", ex.msg, "\n");
    }
}

