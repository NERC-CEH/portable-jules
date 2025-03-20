# Executed every time a new devbox shell is created

if [[ ! $DEVBOX_SHELL_ENABLED -eq 1 ]]; then
    echo "Value of \$DEVBOX_SHELL_ENABLED is: $DEVBOX_SHELL_ENABLED"
    echo "This script must be run inside a devbox shell"
    exit 1
fi

curr_dir=$PWD
tmpdir=$DEVBOX_PROJECT_ROOT/tmp

mkdir -v $tmpdir
cd $tmpdir

# Download and extract fcm if it doesn't already exist
if [ ! -d $FCM_ROOT ]; then

    # TODO: consider alternatives to hard-coded most recent version
    fcm_version="2021.05.0"
    fcm_release="https://github.com/metomi/fcm/archive/refs/tags/${fcm_version}.tar.gz"

    echo "Downloading and extracting $fcm_release to $FCM_ROOT"

    curl -L $fcm_release | tar -xz
    mv -v fcm-$fcm_version $FCM_ROOT

else
    echo "There is already a directory at $FCM_ROOT. Skipping the download..."
fi

if [ ! -d $JULES_ROOT ]; then

    echo "Downloading JULES"

    # TODO: this downloads the most recent revision. Consider switching to @vn7.5
    # See https://github.com/jmarshrossney/portable-jules/issues/3
    fcm co https://code.metoffice.gov.uk/svn/jules/main/trunk jules

    # NOTE: need to add the -fallow-argument-mismatch -w flags so that gfortran doesn't complain
    printf '\n# We are forced to suppress a gfortran error about non-standard code\nbuild.prop{fc.flags}[jules/src/io/dump/read_dump_mod.F90] = $fflags_common -fallow-argument-mismatch -w' >> jules/etc/fcm-make/platform/custom.cfg

    mv -v jules $JULES_ROOT

else
    echo "There is already a directory at $JULES_ROOT. Skipping the download..."
fi

cd $curr_dir

rmdir -v $tmpdir

# Install Python packages
python -m pip install --upgrade pip -q
python -m pip install -r $DEVBOX_PROJECT_ROOT/requirements.txt -q
