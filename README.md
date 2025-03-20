# Portable JULES

The [Joint UK Land Environment Simulator](https://jules.jchmr.org/) is a [land surface model](https://en.wikipedia.org/wiki/Land_surface_models_(climate)) that has been developed over the last 20 years by a wide community of UK researchers coordinated by the [Met Office](https://www.metoffice.gov.uk/) and the [Centre for Ecology Hydrology](https://www.ceh.ac.uk/).

This repository contains tools that make it easy to run JULES on a typical personal computer running a Unix-based OS, or on cloud-based services such as [DataLabs](https://datalab.datalabs.ceh.ac.uk/).

> [!WARNING]
> I have no prior familiarity with JULES or land surface science, and limited knowledge of FORTRAN. My contribution here is to demonstrate a means of making JULES more portable.


## Quickstart

Before doing anything else you need to request access to the JULES source code by filling out [this form](https://jules-lsm.github.io/access_req/JULES_access.html). 

The following steps assume you are executing commands in a bash shell with `curl` and `git` already installed. Please execute each of them individually rather than copy-pasting the whole thing.


```bash
# Install Nix
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install

# Install devbox
curl -fsSL https://get.jetify.com/devbox | bash

# Clone the repository
git clone https://github.com/jmarshrossney/portable-jules.git
cd portable-jules

# Download packages
devbox install

# Test that everything has worked
devbox run hello

# Download FCM and JULES
# NOTE: this step requires MOSRS credentials
devbox run setup

# Build JULES
devbox run build

# Confirm that jules.exe exists in $PATH
# (should return /path/to/portable-jules/build/build/bin/jules.exe)
devbox run which jules.exe

# Run the Loobos example
devbox run loobos
```

## Usage

The simplest way to run a JULES simulation using `portable-jules` is to run the following in the repository root,

```bash
devbox run jules path/to/namelist_dir
```

Under the hood, this will `cd` to `namelist_dir` and run `jules.exe > stdout.log 2> stderr.log`.

One can also specify an alternative working directory using the `-d` flag,

```bash
devbox run jules -d path/to/exec_dir path/to/namelist_dir
```

> [!TIP]
> All relative paths specified in the namelist (`.nml`) files are relative to the working directory, _not_ the namelist file itself.


To execute the `devbox run jules` command from a different directory, one can specifiy the devbox config explicitly, as in

```bash
devbox run -c path/to/portable-jules/devbox.json jules -d path/to/namelist_dir
```

To do: add link to example of running this from a Jupyter notebook

See `scripts/jules_run.sh` for further details.


## What's the point?

The majority of the available documentation for JULES assumes that the user intends to run the model on one of a small number of supported HPC systems - usually [JASMIN](https://jasmin.ac.uk/) (NERC) or [Cray](https://www.metoffice.gov.uk/about-us/who-we-are/innovation/supercomputer) (Met Office) - using a particular suite of configuration and workflow management tools developed by the Met Office.
The fact that this assumption reflects the needs of the majority of users is clearly self-perpetuating, and there seems to be a growing appreciation that this accessibility barrier is a problem.

JULES is ultimately 'just' a FORTRAN-90 model, and it ought to be straightforward to build and run a simple simulation on a standard desktop running a Unix-based OS.
In fact the [technical documentation](https://jules-lsm.github.io/latest/index.html) can get you most of the way there, provided you're prepared for a bit of trial-and-error (and keep in mind that the documentation is incomplete and wrong in places).

Of course, the scientific value of these simulations will be minimal, but that is not the point.
The point is to strip away the abstractions and play around with the base model - to have fun and learn!


## Tested platforms

These steps have been tested and found to succeed on the following platforms:

- Ubuntu 22.04
- Datalabs


## To do

### Low-hanging fruit

- [ ] Tidy up the devbox.json - not all of these packages are strictly needed
- [x] Find a simple but meaningful input configuration (Loobos)
- [ ] User configuration (via `direnv`?) for things like the version of FCM and JULES
- [ ] Expand on the 'getting started' instructions using the GitHub Wiki, including instructions for DataLabs users
- [ ] Add some QOL improvements when running in `--pure` mode, e.g. aliases for `nvim`.


### Towards a set of tutorial notebooks

A tutorial based on Loobos:

- [ ] Example notebooks which run JULES and plot/analyse outputs
- [ ] Update the Loobos dataset with more recent data from [here](https://maq-observations.nl/loobos/)
- [ ] Look at previous Loobos tutorials - what actual science do they look at?

A tutorial based elsewhere in the world (Africa?) (**Help wanted!**)

- [ ] Find (and understand) a suitable dataset and configuration
- [ ] Work with others to design a tutorial with some meaningful science.


### Broader aims

- The configuration via FORTRAN namelists is very brittle. Consider approaches for improving reproducibility, including dependency, configuration and data management & version control
- Making it easy to programmatically modify parameters and input data for e.g. sensitivity analyses, generating training data for statistical models etc
- Develop a containerised approach that reduces discontinuity when scaling up to HPC systems (via singularity)


### Ownership

This work was done while at UKCEH - repository will be transferred to [NERC-CEH](https://github.com/NERC-CEH) if/when it becomes useful.
