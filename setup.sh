# Warn user if not in devbox shell
if [[ ! $DEVBOX_SHELL_ENABLED -eq 1 ]]; then
    echo "WARNING: Running outside devbox shell. Did you mean to run this script with 'devbox run'?"
fi

# Check the following environment variables are defined
echo "Checking required environment variables are defined..."
test ! -z "$FCM_ROOT" || { echo "ERROR: missing environment variable 'FCM_ROOT'"; exit 1; }
test ! -z "$JULES_ROOT" || { echo "ERROR: missing environment variable 'JULES_ROOT'"; exit 1; }
test ! -z "$JULES_BUILD_DIR" || { echo "ERROR: missing environment variable 'JULES_BUILD_DIR'"; exit 1; }
test ! -z "$JULES_NETCDF" || { echo "ERROR: missing environment variable 'JULES_NETCDF'"; exit 1; }
test ! -z "$JULES_NETCDF_PATH" || { echo "ERROR: missing environment variable 'JULES_NETCDF_PATH'"; exit 1; }

# Check that FCM and JULES directories are not in use already
echo "Checking that download target directories are not in use already..."
test ! -d "$FCM_ROOT" || { echo "ERROR: directory $FCM_ROOT already exists"; exit 1; }
test ! -d "$JULES_ROOT" || { echo "ERROR: directory $JULES_ROOT already exists"; exit 1; }

# Exit if any subsequent command returns non-zero exit status
set -e

# ------------------------------------------- #
#  Read MOSRS credentials and JULES revision  #
# ------------------------------------------- #

# Attempt to read from env variables, otherwise take default values
REVISION="${JULES_REVISION:-HEAD}"
USERNAME="${MOSRS_USERNAME:-__MISSING__}"
PASSWORD="${MOSRS_PASSWORD:-__MISSING__}"

# Attempt to read from command-line args
while getopts "r:u:p:" opt; do
    case $opt in
        r)
            REVISION=$OPTARG
	    ;;
	u)
	    USERNAME=$OPTARG
	    ;;
	p)
	    PASSWORD=$OPTARG
	    ;;
	\?)
	    echo "Invalid option: -$OPTARG" >&2
	    exit 1
	    ;;
	:)
	    echo "Option -$OPTARG requires an argument." >&2
	    exit 1
	    ;;
    esac
done

# Check that MOSRS credentials have been set
if [ "$USERNAME" = "__MISSING__" ] || [ "$PASSWORD" = "__MISSING__" ]; then
    echo "Must provide a username and password!"
    exit 1
fi

# ----------------------- #
#  Download fcm and JULES #
# ----------------------- #

# Switch to temporary directory
cwd="$PWD"
tmpdir="$(mktemp -d)"
cd "${tmpdir}"  # curly braces incase $tmp is defined

# NOTE: hard-coded most recent version, but releases are *very* infrequent
fcm_version="2021.05.0"
fcm_release="https://github.com/metomi/fcm/archive/refs/tags/${fcm_version}.tar.gz"

echo "Downloading and extracting $fcm_release to $FCM_ROOT"
curl -L $fcm_release | tar -xz

echo "Downloading JULES, revision $REVISION"
svn checkout --non-interactive --no-auth-cache  \
    --username "$USERNAME" --password "$PASSWORD" \
    https://code.metoffice.gov.uk/svn/jules/main/trunk --revision "$REVISION" \
    jules

# NOTE: need to add the -fallow-argument-mismatch -w flags to the config file
# jules/etc/fcm-make/platform/custom.cfg otherwise gfortran refuses to build
printf '\n# We are forced to suppress a gfortran error about non-standard code\nbuild.prop{fc.flags}[jules/src/io/dump/read_dump_mod.F90] = $fflags_common -fallow-argument-mismatch -w' >> jules/etc/fcm-make/platform/custom.cfg

#  Move downloaded code out of tempdir
mkdir -p -v "$(dirname $FCM_ROOT)"
mv -v fcm-$fcm_version "$FCM_ROOT"

mkdir -p -v "$(dirname $JULES_ROOT)"
mv -v jules "$JULES_ROOT"

# Return to original directory and delete temporary directory
cd "$cwd"
rm -r "${tmpdir}"

# ------------- #
#  Build JULES  #
# ------------- #

mkdir -p -v "$JULES_BUILD_DIR"
echo "Building JULES"
"$FCM_ROOT/bin/fcm" make -f "$JULES_ROOT/etc/fcm-make/make.cfg" -C "$JULES_BUILD_DIR" --new

echo "Setup completed successfully"
