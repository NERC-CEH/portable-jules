# Check inside devbox shell
if [[ ! $DEVBOX_SHELL_ENABLED -eq 1 ]]; then
    echo "Value of \$DEVBOX_SHELL_ENABLED is: $DEVBOX_SHELL_ENABLED"
    echo "This script must be run inside a devbox shell"
    exit 1
fi

# If -d is provided, it *needs* to be the first argument!
for arg in "${@:2}"; do
    if [[ "$arg" == "-d" ]]; then
        echo "Usage: cmd [-d exec_dir] namelist_dir ..."
        exit 1
    fi
done

# Check if -d is provided
exec_dir=""
while getopts ":d:" opt; do
    case ${opt} in
        d )
            exec_dir=$OPTARG
            ;;
        \? )
        echo "Usage: cmd [-d exec_dir] namelist_dir ..."
        exit 1
        ;;
    esac
done

# Remove optional args (-d exec_dir) so that positional parameters can be accessed as usual
shift $((OPTIND -1))

# Function to run JULES once, given a namelist directory
run_jules() {
    local curr_dir=$(pwd)
    local namelist_dir="$1"

    if [ ! -d "$1" ]; then
        echo "Provide an existing namelist directory (given $1)"
        return
    fi

    # Determine directory in which jules.exe should be executed
    if [ -z "$exec_dir" ]; then
        exec_dir="$namelist_dir"
    fi  

    # Hack to get absolute paths
    namelist_abspath=$(cd "$namelist_dir"; pwd)
    exec_abspath=$(cd "$exec_dir"; pwd)

    # Extract output dir (hard-coded into output.nml)
    # TODO: should attempt to check if relative or absolute!
    cd "$namelist_abspath"
    output_dir=$(grep "output_dir" output.nml | sed -E "s/output_dir\s*=\s*'([^']*)'.*/\1/")
    
    echo "Changing directory to $exec_abspath"
    cd "$exec_abspath"

    # Create output_dir if it doesn't exist already
    mkdir -p -v "$output_dir"

    echo "Running jules.exe $namelist_abspath"
    jules.exe $namelist_abspath > stdout.log 2>stderr.log

    # Echo any errors to stdout
    if grep -q "ERROR" stderr.log; then
        grep "ERROR" stderr.log
    else
        echo "No errors raised!"
    fi

    # Return to original dir
    cd "$curr_dir"
}

export -f run_jules


if [ "$#" -eq 1 ]; then
    run_jules "$1"

elif [ "$#" -gt 1 ]; then
    echo "Running Jules in parallel with all provided namelists"
    parallel run_jules ::: "$@"

else
    echo "Usage: cmd [-d exec_dir] namelist_dir ..."
    exit 1
fi

