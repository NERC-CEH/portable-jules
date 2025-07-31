# Warn user if not in devbox shell
if [[ ! $DEVBOX_SHELL_ENABLED -eq 1 ]]; then
    echo "WARNING: Running outside devbox shell. Did you mean to run this script with 'devbox run'?"
fi

# Grab jules.exe from PATH, for now at least
jules_exe=$(command -v jules.exe) || { echo "ERROR: jules.exe not found"; exit 1; }

# If -d or -n is provided, it *needs* to be the first argument!
for arg in "${@:2}"; do
    if [[ "$arg" == "-n" ]]; then
        echo "Usage: cmd [-n namelists_subdir ] exec_dir [exec_dir_2 ...]"
        exit 1
    fi
done

# Check if -n is provided
namelists_subdir=""
while getopts ":n:" opt; do
    case ${opt} in
    n )
        namelists_subdir=$OPTARG
        ;;
    \? )
        echo "Usage: cmd [-n namelists_subdir ] exec_dir [exec_dir_2 ...]"
        exit 1
        ;;
    esac
done

# Remove optional args (-n namelists_subdir) so that positional parameters can be accessed as usual
shift $((OPTIND -1))

# Function to run JULES once, given a namelist directory
run_jules() {
    if [ -z "$1" ] || [ -z "$2" ] || [ -z "$3" ]; then
        echo "Usage: run_jules jules_exe exec_dir namelists_dir"
        exit 1
    fi

    local jules_exe="$1"
    local exec_dir="$2"
    local namelists_subdir="$3"
    local curr_dir=$(pwd)

    # Check that exec_dir exists
    if [ ! -d "$exec_dir" ]; then
        echo "Directory not found: $exec_dir"
        exit 1
    fi

    # If namelists_subdir not given, namelists_dir is exec_dir
    if [ -z "$namelists_subdir" ]; then
        namelists_dir="$exec_dir"
    else
        namelists_dir="${exec_dir}/${namelists_subdir}"
    fi

    # Check that namelists_dir exists and contains output.nml
    if [ ! -d "$namelists_dir" ]; then
        echo "Directory not found: $namelists_dir"
        exit 1
    fi
    if [ ! -f "${namelists_dir}/output.nml" ]; then
        echo "File not found: ${namelists_dir}/output.nml - no a valid namelists directory."
        exit 1
    fi

    # Hack to get absolute paths
    namelist_abspath=$(cd "$namelists_dir"; pwd)
    exec_abspath=$(cd "$exec_dir"; pwd)

    # Extract output dir (hard-coded into output.nml)
    # TODO: should attempt to check if relative or absolute!
    cd "$namelist_abspath"
    output_dir=$(grep "output_dir" output.nml | sed -E "s/^[ \t]*output_dir\s*=\s*'([^']*)'.*/\1/")

    echo "Changing directory to $exec_abspath"
    cd "$exec_abspath"

    # Create output_dir if it doesn't exist already
    mkdir -p -v "$output_dir"

    echo "Running $jules_exe $namelist_abspath"
    "$jules_exe" "$namelist_abspath" > stdout.log 2>stderr.log

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
    run_jules "$jules_exe" "$1" "$namelists_subdir"

elif [ "$#" -gt 1 ]; then
    echo "Running Jules in parallel with all provided directories"
    parallel run_jules "$jules_exe" {} "$namelists_subdir" ::: "$@"

else
    echo "Usage: cmd [-n namelists_subdir ] exec_dir [exec_dir_2 ...]"
    exit 1
fi

