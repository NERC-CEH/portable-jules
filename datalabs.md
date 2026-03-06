# Using `portable-jules` in UKCEH DataLabs

These instructions explain how to download, build and run JULES on UKCEH DataLabs.

> [!WARNING]
> DataLabs was not built for this. I have done my best to make the process as smooth as possible
> but it is still very awkward. My recommendation remains to pressure the Met Office to release JULES
> under an open source license, which would allow us to distribute a containerised version of JULES
> that could be run on more robust systems than DataLabs. Or, failing this, use a different land surface
> model.

> [!WARNING]
> DataLabs runs containerised instances of Ubuntu Linux, which it seems are periodically destroyed and
> recreated, preserving only the user data in the `/data/` directory. This means any files created or
> libraries installed elsewhere must be periodically recreated or reinstalled.

> [!NOTE] 
> You will need to be an admin on your datalabs project for these steps to work.


## Installing core libraries

Run the following commands in a terminal instance.

```sh
sudo apt update
sudo apt install --yes \
	coreutils \
	curl \
	diffutils \
	git \
	gfortran \
	glibc-source \
	make \
	libnetcdf-dev \
	libnetcdff-dev \
	parallel \
	perl \
	subversion
```

> [!WARNING]
> Following the earlier observation that DataLabs periodically destroys and recreates everything except
> the contents of `/data`, you may find that these libraries have been deleted after a few days (or hours
> if you're unlucky). If this happens, you will need to reinstall them. In particular, the JULES executable
> will not run if the two netcdf libraries are not detected.

## Clone the `portable-jules` repository

Clone the repository and navigate to the repository root directory:

```sh
git clone https://github.com/NERC-CEH/portable-jules.git
cd portable-jules
```


## Build JULES

You will need to set some environment variables before running the setup script. For a 'basic' installation these will be:

- `MOSRS_USERNAME` : your MOSRS username
- `FCM_ROOT` : location to download FCM
- `JULES_ROOT` : location to download JULES
- `JULES_BUILD_DIR` : location for JULES build
- `JULES_NETCDF` : flag for whether to use netcdf or not (this should be set to `netcdf`)
- `JULES_NETCDF_PATH` : path to a location containing containing the netcdf include directory (the file `netcdf.mod` should be found in `$JULES_NETCDF_PATH/include`.)

See the [JULES documentation](https://jules-lsm.github.io/latest/building-and-running/fcm.html#environment-variables-used-when-building-jules-using-fcm-make) for a full list of environment variables.

It is convenient to store these in a file, as this example shows.

```sh
# portable-jules/.env
FCM_ROOT=/path/to/portable-jules/_download/fcm
JULES_ROOT=/path/to/portable-jules/_download/jules
JULES_BUILD_DIR=/path/to/portable-jules/_build
JULES_NETCDF=netcdf
JULES_NETCDF_PATH=/usr  # works for ubuntu after apt installing netcdf
JULES_REVISION=30414  # vn7.9
```

Finally, you should be able to run the setup and run scripts in the usual way:

```bash
# Make executable
chmod +x setup.sh jules.sh  

set -a  # causes `source .env` to export all variables
source .env
set +a

# Download and build
./setup.sh -u <mosrs_username> -p '<mosrs_password>'
```

In the above, `<mosrs_username` should be replaced by your MOSRS username, and `<mosrs_password>` replaced by your MOSRS password. Note the use of single quotation marks, which ensures the password is treated as a literal string, so any illegal characters don't mess things up.

If the setup script worked, the JULES executable should be located at `portable-jules/_build/build/bin/jules.exe`.


## Installing Python dependencies

To work with netcdf input/output data from a `jupyter`` notebook, I recommend using `xarray`.


The default Python environment in DataLabs is a very old one (3.11), containing old versions of `numpy`, `matplotlib` etc managed by the `conda` package manager. Because of this, it is important to make sure you install any additional Python packages using `conda install` as much as possible, so that they are compatible.

```sh
conda install xarray
```

If you try to `pip install xarray` it will most likely install a newer version that is incompatible with the `numpy` and `pandas` versions already present.

Note that while it is possible to install a more recent version of Python and change the Python interpreter used by Jupyter, it requires a fair amount of technical know-how to do on DataLabs, even if it's something you're used to doing on your personal computer.

## Installing JULES-specific tools

You can run `jules.exe` from a `jupyter` notebook using e.g. `subprocess.run` or `! path/to/jules.exe`, but it's not recommended since you need to be careful managing your paths to namelists and data.

I recommend using [`jules-tools`](https://github.com/nerc-ceh/jules-tools), which providers a thin Python wrapper around a JULES executable that conveniently resolves namelist paths.

These packages are not `conda` installable. At the top of your notebook, add a cell that runs

```sh
! pip install https://github.com/jmarshrossney/metaconf
! pip install https://github.com/nerc-ceh/jules-tools
```

## Running JULES

The following cells runs the Loobos example that is provided along with `portabe-jules`.

```python
from pathlib import Path

import pandas as pd
import matplotlib.pyplot as plt
import xarray as xr

from jules_tools.runners import JulesExeRunner
```

```python
# Specify the path to the jules executable
jules_exe = Path("/path/to/portable-jules/_build/build/bin/jules.exe")

# Specify the path to the config
config_path = Path("/path/to/portable-jules/examples/loobos")

# Create a JulesExeRunner object
jules = JulesExeRunner(jules_exe)
```

```python
# Specify paths
cwd = Path.cwd()  # current working directory
print(cwd)

run_dir = cwd / "loobos"  # run JULES in the 'loobos' directory
nml_dir = run_dir / "namelists"  # directory containing namelists
output_dir = run_dir / "outputs"  # directory where outputs will be saved (this should agree with the path set in outputs.nml)

# Copy a 'clean' version of the loobos directory from the portable-jules repository
shutil.copytree(config_path, run_dir)

# Create the output directory if it doesn't exist already
output_dir.mkdir(exist_ok=True)

# Throw an error if any of these directories do not exist
assert run_dir.is_dir()
assert nml_dir.is_dir()
assert output_dir.is_dir()
```

```python
# Bring up the documentation for the JULES runner
jules?
```

```python
# THIS RUNS THE MODEL
jules(run_dir, namelists_subdir="namelists")
```

```python
# Load the output data using xarray
ds = xr.open_dataset(output_dir / "loobos.test.nc")

ds
```
