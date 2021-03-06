# stubbs: A module and command set to create rerun modules

Use `stubbs` to define new *rerun* modules and commands.

Stubbs provides a small set of commands that 
help you define and organize modules according to
rerun layout conventions and metadata format. 

It won't write your implementations for you but
helps you stay in between the guard rails!

## Commands

### add-module

Create a new rerun module.

*Usage*

    rerun stubbs:add-module [--module <>] [--description <>]
    
*Example*

Make a new module named "freddy":

    rerun stubbs:add-module --module freddy --description "A dancer in a red beret and matching suspenders"

The `add-module` command will print:

    Created module structure: /Users/alexh/.rerun/modules/freddy

### add-command

Create a command in the specified module and generate a default implementation.

*Usage*

    rerun stubbs:add-command --command <> --description <> --module <> [--ovewrite <false>]

*Example*

Add a command named "dance" to the freddy module:

    rerun stubbs:add-command --command dance --description "tell freddy to dance" --module freddy

The `add-command` module will generate a boilerplate script file you can edit.

	Wrote command test: /Users/alexh/.rerun/modules/freddy/tests/commands/dance/default.sh
	Wrote command script: /Users/alexh/.rerun/modules/freddy/commands/dance/default.sh

Of course, stubbs doesn't write the implementation for you, merely a stub.

See the "Command implementation" section below to learn about 
the `default.sh` script.

See the "Testing" section below to learn about
the `test.sh` script.

### add-option

Define a command option for the specified module and generate options parser script.

*Usage*

    rerun stubbs:add-option [--arg <true>] --option <> --description <> --module <> --command <> [--required <false>]

*Example*

Define an option named "--jumps":

    rerun stubbs:add-option --option jumps --description "jump #num times" --module freddy --command dance

You will see output similar to:

    Created option: /Users/alexh/.rerun/modules/freddy/commands/dance/jumps.option

Besides the `jumps.option` file, `add-option` also generates an
option parsing script: `$RERUN_MODULES/$MODULE/commands/$COMMAND/options.sh`.

The `default.sh` script sources the `options.sh` script to take care of
command line option parsing.

Users will now be able to specify a "--jumps" argument to the `freddy:dance` command:

    $ rerun freddy
    freddy:
    [commands]
     dance: tell freddy to dance
      [options]
        --jumps <>: "jump #num times"

### archive

The `archive` command will produce
a bash self extracting archive script (aka. a .bin file)
useful for launching a self contained rerun environment.

Use `stubbs:archive` to save a set of specified modules and
the `rerun` executable into a single file that can easily
be copied across the network.

`archive` generates a script that takes the same argument
list as `rerun`. This generated script basically acts
like a `rerun` launcher.

*Usage*

    rerun stubbs:archive [--file <>] [--modules <"*">] [--version <>]

*Example*

Create an archive containing the "freddy" module:

    rerun stubbs:archive --modules "freddy"

The `archive` command generates a "rerun.bin" file 
in the current directory.

Run the self extracting archive script without options and you
will see freddy's commands listed:

    $ bash rerun.bin
    freddy:
    [commands]
     dance: tell freddy to dance
      [options]
        --jumps <>: "jump #num times"

Now run the `freddy:dance` command.

    $ bash rerun.bin freddy:dance --jumps 10
    jumps (10)

It works like a normal `rerun` command. Amazing !

*Internal details*

The archive format is a base64 encoded gzip'd tar file appended to a bash shell script
(e.g., cat EXTRACTSCRIPT PAYLOAD.tgz.base64 > RERUN.BIN).

The tar file contains payload content, specifically rerun and modules.

When the archive file is executed, 
the shell script reads the binary "attachment",
decompresses and unarchives the payload and then invokes
the rerun launcher.

The rerun launcher creates an ephemeral workspace to load
the included modules and then executes the included `rerun`
executable in the user's current working directory.

Refer to the source code implementation for further details.

### docs

Generate the docs.

*Usage*

    rerun stubbs:docs --module <>
    
*Example*

Generate the manual page for "freddy" module:

    rerun stubbs:docs --module freddy

The `docs` command will print:

    Generated unix manual: /Users/alexh/rerun-workspace/rerun/modules/freddy/freddy.1


Run `rerun --manual <module>` to display it:
	
	rerun --manual freddy
	
### test

Run module test suite

*Usage*

    rerun stubbs:test [--module <>] [--command <>] [--logs <>]
    
*Example*

Run the test suite for the module named "freddy":

    rerun stubbs:test --name freddy

The `test` command will print output similar to the following:

	[tests]  
	  freddy:dance: OK

Each command that has any unit test scripts will be tested.

See the "Testing" section below to learn about
the test framework.

## Command implementation

Running `stubbs:add-command` as shown above will generate a stub default implementation
for the new command: `$RERUN_MODULES/$MODULE/commands/$COMMAND/default.sh`:

The dance command's `default.sh` stub is shown below.

File listing: `$RERUN_MODULES/freddy/commands/dance/default.sh`

    #!/usr/bin/env bash
    #
    # NAME
    #
    #   dance 
    #
    # DESCRIPTION
    #
    #   tell freddy to dance
     
    # Function to print error message and exit
    rerun_die() {
        echo "ERROR: $* " ; exit 1;
    }
     
    # Parse the command options     
    [ -r $RERUN_MODULES/freddy/commands/dance/options.sh ] && {
       . $RERUN_MODULES/freddy/commands/dance/options.sh
    } 
     
    # ------------------------------
    # Your implementation goes here.
    # ------------------------------
     
    exit $?

The name and description supplied via `add-command` options
are inserted as comments at the top.

A `rerun_die` function is provided for convenience in case things go awry.

Rather than implement a specialized option parser logic inside
each command implementation, `add-option` generates a reusable
script sourced by the command implementation script.
When your command is run all arguments passed after the "--"
are parsed by the options.sh script.

Naturally, your implementation code goes between the rows
of dashes. 
For this example, insert `echo "jumps ($JUMPS)` as a trivial
implementation:

    # ------------------------------
    echo "jumps ($JUMPS)"
    # ------------------------------
    
    exit $?

Always faithfully check and return useful exit codes!

Try running the `freddy:dance` command:

    $ rerun freddy:dance --jumps 3
    jumps (3)

The "jumps (3)" is written to the console standard output.

Run `freddy:dance` again but this time without options.

    $ rerun freddy:dance
    jumps ()

This time an empty pair of parenthesis is printed.
The problem is this: the `$JUMPS` variable was not set
so an empty string is printed instead.
    
### Option defaults

If a command option is not supplied by the user, the
`options.sh` script (created by `add-option`) 
can set a default value.

Call the `add-option` command again but this
time use its `--default <>` parameter to set the default value. 

Here the "--jumps" option is set to a default value, "1":

    rerun stubbs:add-option \
      --name jumps -description "jump #num times" --module freddy --command dance \
      --default 1

The `add-option` will update the `jumps.option` metadata file with the
new default value and extend the `options.sh` script.

Run the `freddy:dance` command again but this time without the "--jumps" option:

    $ rerun freddy:dance
    jumps (1)

We see the default value "1" printed.
    
You might be interested in the `options.sh` script
that's created behind the scenes.
Below, the "dance" command's `options.sh` script is shown.
It defines a while loop 
and supporting shell functions to process command line input.

The meat of the script is the while loop and case statement.
In the body of the case statement, you can see a case for
the "--jumps" option and the `JUMPS` variable that will be set
to the value of the "--jumps" argument.

    # generated by add-option
    # Tue Sep 13 20:11:52 PDT 2011
     
    # print error message and exit non-zero
    rerun_option_error() {
        echo "SYNTAX ERROR" >&2 ; exit 2;
    }
    # check option has its argument
    rerun_option_check() {
        [ "$1" -lt 2 ] && syntax_error
    }
     
    # options: [jumps]
    while [ "$#" -gt 0 ]; do
        OPT="$1"
        case "$OPT" in
            -j|--jumps) rerun_option_check $# ; JUMPS=$2 ; shift ;;
            # unknown option
            -?)
                rerun_option_error
                ;;
            # end of options, just arguments left
            *)
              break
        esac
        shift
    done
          
    # If defaultable options variables are unset, set them to their DEFAULT
    [ -z "$JUMPS" ] && JUMPS=1 
     
Below the `while` loop, you can see a test for the
JUMPS variable (check for empty string).
A statement like this is added for options that declare 
`DEFAULT` metadata.

Separating options processing into the `options.sh` script,
away from the command implementation logic in `default.sh`, facilitates
additional options being created. It also helps "stubbs"
preserve changes you make to `default.sh` or other scripts
that source `options.sh`.

### OS specific command implementations

Your command's `default.sh` implementation may not work in all operating
system environments due to command and/or syntax differences.

Rerun will look for an operating system specific 
command implementation and run it instead, if it exists.

Effectively, rerun checks for a file named: 
`$MODULE/commands/$COMMAND/$(uname -s).sh`

For example, run `uname -s` on a centos host to see the name of the
operating system. It returns "Linux".

    $ uname -s
    Linux

So, to create a Linux OS specific implementation,
create a script called `Linux.sh`. Copy default.sh
as a starting point:

    cp freddy/commands/dance/default.sh freddy/commands/dance/Linux.sh

Running the `tree` command shows the directory structure.

    freddy
    └── commands
        └── dance
            ├── Linux.sh (os-specific implementation)
            └── default.sh (generic one)
	    
Inside the Linux.sh script, replace the implementation with:

     echo "I'm a locker"
     
Run the `freddy:dance` command:

    $ rerun freddy:dance
    I'm a locker

The result comes from rerun's execution of the new `Linux.sh` script.

### Verbosity?

What happens when your command implementation fails and
all you see is one line of cryptic error text?
Shed more light by enabling verbose output using rerun's `-v` flag.

Adding '-v' effectively has `rerun` call the command
implementation script with bash's "-vx" flags. 

Here's a snippet of the `freddy:dance` command with verbose output:

    rerun -v freddy:dance
    .
    . <spipping out most of the verbose output ... >
    .
    # ------------------------------
    echo "jumps ($JUMPS)"
    + echo 'jumps (3)'
    jumps (3)
    # ------------------------------
    exit $?
    + exit 0

### Example: freddy

This section describes how to define the "freddy" module used
through the documentation.

Create the "freddy" module:

	rerun stubbs:add-module --module freddy --description "A dancer in a red beret and matching suspenders"

Create the `freddy:study` command:

	rerun stubbs:add-command --command study \
	   --description "tell freddy to study" --module freddy

Define an option called "-subject":

	rerun stubbs:add-option --option subject \
	   --description "subject to study" --module freddy --command study \
	   --default math --required false

Edit the default implementation (`RERUN_MODULES/freddy/commands/study/default.sh`).
The implementation should echo what freddy is studying:

	# ------------------------------
	echo "studying ($SUBJECT)"
	# ------------------------------

Similarly, define the `freddy:dance` command:

	rerun stubbs:add-command --command dance \
		   --description "tell freddy to dance" --module freddy

Define an option called "--jumps":

	rerun stubbs:add-option --option jumps \
		   --description "jump #num times" --module freddy --command dance \
		   --default 1 --required false

Edit the default implementation (`RERUN_MODULES/freddy/commands/dance/default.sh`).
The implementation should echo how many jumps:

	# ------------------------------
	echo "jumps ($JUMPS)"
	# ------------------------------

The freddy commands, their options and default implementations are completed.
Use rerun listing to show the command usage:

	$ ./rerun freddy
	[commands]
	 dance: "tell freddy to dance"
	  [options]
	    [-j|--jumps <1>: "jump #num times"]
	 study: "tell freddy to study"
	  [options]
	    [-s|--subject <math>: "subject to study"]

The "dance" and "study" commands are listed. 
Try `freddy:study` with and without options.
Since a default value was assigned to "--subject"
(remember "--default math" was specified to `stubbs:add-option`),
the subject "math" will be printed.

Without option:

	$ ./rerun freddy: study
	studying (math)

With option:

	$ ./rerun freddy: study --subject locking
	studying (locking)

## Testing 

Stubbs provides very basic support for unit testing modules.
Each module can contain a test suite of scripts.
Stubbs will run a module's tests via the `test` command.

Here the unit tests for the "freddy" module are executed via `stubbs:test`:

	rerun stubbs:test --module freddy
	[tests]  
	  freddy:dance: OK
	  freddy:study: OK

A successful unit test will print `OK` while a failed one 
will print `FAIL` and cause rerun to exit non zero.

Stubbs creates a unit test for every command that is created
through `stubbs:add-command`.
When `add-command` is run, a boiler plate unit test script
is generated and added to the module's test suite.

Below is a partial view of "freddy" module files. Notice
how the `tests` directory closely parallels the `commands`
directory.

If the contents of the `tests` directory remind you
of a rerun module structure, you would be correct!
Rerun test suites are based on rerun modules themselves.

	modules/freddy
	├── commands
	│   └── dance
	│       ├── default.sh
	│       ├── jumps.option
	│       ├── metadata
	│       └── options.sh
	├── etc
	├── metadata
	└── tests
	    ├── commands
	    │   └── dance
	    │       ├── default.sh
	    │       └── metadata
	    └── metadata

You can see this by listing the unit tests in the suite.
Below you see the `-M <dir>` option used to
specify the freddy module directory as the modules directory:
	
	$ rerun -M $RERUN_MODULES/freddy tests
	[commands]
	 dance: "test freddy dance"
	  [options]

This example shows there is one unit test in the 
freddy test suite.

### Test logs

The output from the test script execution is stored in
the directory specified by `--logs <>` option or it will
defaulted to `$(pwd)/tests-reports`.

Here's a sample test report listing for the 'freddy' test suite.

	test-reports
	├── TEST-freddy.txt
	├── TEST-freddy:dance.default.sh.txt
	├── TEST-freddy:dance.default.sh.txt.stderr
	├── TEST-freddy:dance.txt
	├── freddy-dance-2011-0921-194512.log
	└── tests-dance-2011-0921-194511.log

Cat the file named TEST-$MODULE.txt to see a summary:

	$ cat test-reports/TEST-freddy.txt 
	Testsuite: freddy
	Tests run: 1, Failures: 0, Time elapsed: 1 s

### Tests scripts

Test scripts should return with a 0 (zero) exit 
status upon successful test validation.

The implementation of the individual test scripts 
are completely open to anything the author wishes
to do. 

That said, it is possible to further leverage rerun
conventions to facilitate testing.

Here's an example script that began as a boiler
plate generated by `add-command`. Notice how
this script contains several rough sections:

1.  The rerun executable and module path are declared.
2.  Test functions loaded.
3.  Test session is created defining the command execution.
4.  Test shell functions used to define unit tests.

File listing: `$RERUN_MODULES/freddy/tests/dance/commands/default.sh`

    # Commands covered: dance
    #
    # This file contains test scripts to run for the dance command.
    # Execute it by invoking: 
    #    
    #                rerun stubbs:test -m freddy -c dance
    #
    # The test report can be found in:
    #
    #                test-reports/TEST-freddy:dance.txt
    #
     
    # 
    # The rerun command environment
    #
    RERUN="./rerun"
    RERUN_MODULES="/Users/alexh/rerun-workspace/rerun/modules"
    # 
    # Load the test function library
    #
    source $RERUN_MODULES/stubbs/lib/test.sh || exit 1
     
    #
    # Create a test execution session for the command
    #
    typeset -a test
    test=( $(test:session $RERUN $RERUN_MODULES freddy dance "") ) || {
        test:exit 1 "error creating session" 
    }
     
    #
    # test 1
    #
    test:pass $test || test:fail $test "test1: execution failure"



It's also possible to execute this test script directly.

	$ bash $RERUN_MODULES/freddy/tests/commands/dance/default.sh 
	jumps (3)


# LICENSE

Licensed under the Apache License, Version 2.0 (the "License"); 
you may not use this file except in compliance with the License. 
You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, 
software distributed under the License is distributed on an 
"AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, 
either express or implied. See the License for the specific 
language governing permissions and limitations under the License.

The rerun source code and all documentation may be downloaded from
<https://github.com/dtolabs/rerun/>.
