# Portable JULES

<!-- [![Built with Devbox](https://www.jetify.com/img/devbox/shield_galaxy.svg)](https://www.jetify.com/devbox/docs/contributor-quickstart/) -->
[![Built with Devbox](https://www.jetify.com/img/devbox/shield_moon.svg)](https://www.jetify.com/devbox/docs/contributor-quickstart/)

The [Joint UK Land Environment Simulator](https://jules.jchmr.org/) is a [land surface model](https://en.wikipedia.org/wiki/Land_surface_models_(climate)) that has been developed over the last 20 years by a wide community of UK researchers coordinated by the [Met Office](https://www.metoffice.gov.uk/) and the [Centre for Ecology Hydrology](https://www.ceh.ac.uk/).

This repository contains tools that make it easy to run JULES on a typical personal computer running a Unix-based OS, or on cloud-based services such as [DataLabs](https://datalab.datalabs.ceh.ac.uk/).

> [!WARNING]
> I have no prior familiarity with JULES or land surface science, and limited knowledge of FORTRAN. My contribution here is to demonstrate a means of making JULES more portable.


## Quickstart

Before doing anything else you need to request access to the JULES source code by filling out [this form](https://jules-lsm.github.io/access_req/JULES_access.html). You should then be provided with a Met Office Science Repository Service (MOSRS) username and password.

Clone the repository and navigate to the repository root directory:

```sh
git clone https://github.com/jmarshrossney/portable-jules.git
cd portable-jules
```

Next, create a file called `.env` in the root of the repository containing the following lines:

```env
# file .env
MOSRS_USERNAME="<your MOSRS username>"
MOSRS_PASSWORD="<your MOSRS password>"
```

Replace `<your MOSRS username>` and `<your MOSRS password>` with, you guessed it, your MOSRS username and password.

The following steps assume you are executing commands in a bash shell with `curl` (and `git`) already installed. Please execute each of them individually rather than copy-pasting the whole thing.


```bash
# Install devbox
curl -fsSL https://get.jetify.com/devbox | bash

# Download packages
devbox install

# Test that everything has worked
devbox run hello

# Download FCM and JULES
# NOTE: this step requires MOSRS credentials
devbox run --env-file .env setup

# Build JULES
devbox run build

# Confirm that jules.exe exists in $PATH
# (should return /path/to/portable-jules/build/build/bin/jules.exe)
devbox run which jules.exe

# Run the Loobos example
devbox run loobos
```

## Usage

### Basic

The simplest way to run a JULES simulation using `portable-jules` is to run the following in the repository root,

```bash
devbox run jules path/to/namelist_dir
```

Under the hood, this will `cd` to `namelist_dir` and run `jules.exe > stdout.log 2> stderr.log`.
(See `scripts/jules_run.sh` for further details.)

One can also specify an alternative working directory using the `-d` flag,

```bash
devbox run jules -d path/to/exec_dir path/to/namelist_dir
```

> [!TIP]
> All relative paths specified in the namelist (`.nml`) files are relative to the working directory, _not_ the namelist file itself.


### Parallel

It is possible to fire off several JULES runs at once using [GNU Parallel](https://www.gnu.org/software/parallel/) by providing multiple namelist directories,

```bash
# Specify individual namelist directories...
devbox run jules path/to/namelists_1 path/to/namelists_2 ...

# ...or use a wildcard
devbox run jules path/to/dir_of_namelist_dirs/*
```

This is useful for running large ensembles of 1+1 dimensional 'point' simulations, which includes gridded simulations that are completely decoupled in the spatial dimensions.


### In other projects

To execute the `devbox run jules` command from a different directory, one can specifiy the devbox config explicitly, as in

```bash
devbox run -c path/to/portable-jules/devbox.json jules -d path/to/namelist_dir
```

**To do:** add link to example of running this from a Jupyter notebook.


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


## Revisions

By default, `devbox run setup` will download the most recent revision of JULES (i.e. `HEAD`). However, one can specify a revision by passing a single positional argument, as in `devbox run setup <rev>`.

The following (copied from [here](https://code.metoffice.gov.uk/trac/jules/browser/main)) maps named versions of JULES to revision identifiers. To download version 7.8, for example, one would do `devbox run setup 29791`.

```
vn3.1 = 11
vn3.2 = 27
vn3.3 = 52
vn3.4 = 65
vn3.4.1 = 67
vn4.0 = 101
vn4.1 = 131
vn4.2 = 793
vn4.3 = 1511
vn4.3.1 = 1709
vn4.3.2 = 1978
vn4.4 = 2461
vn4.5 = 3197
vn4.6 = 4285
vn4.7 = 5320
vn4.8 = 6925
vn4.9 = 8484
vn5.0 = 9522
vn5.1 = 10836
vn5.2 = 12251
vn5.3 = 13249
vn5.4 = 14197
vn5.5 = 15100
vn5.6 = 15927
vn5.7 = 16960
vn5.8 = 17881
vn5.9 = 18812
vn6.0 = 19395
vn6.1 = 20512
vn6.2 = 21512
vn6.3 = 22411
vn7.0 = 23518
vn7.1 = 24383
vn7.2 = 25256
vn7.3 = 25896
vn7.4 = 26897
vn7.5 = 28091
vn7.6 = 28692
vn7.7 = 29181
vn7.8 = 29791
vn7.8.1 = 29986
vn7.9 = 30414
```

## Docker container

As part of the process of building a container image, the JULES source code needs to be downloaded, which requires MOSRS credentials. We cannot simply copy `.env` into the container since that would mean anyone could spin up the container and inspect it. We need to expose the contents of `.env` during the build in a secure way.

This solution is to use a [_secret mount_](https://docs.docker.com/build/building/secrets/). In the following example, we mount `.env` during the build:

```sh
docker build --secret id=.env -t jules:vn7.9 .
```

The contents of `.env` are then accessible using: `RUN --mount=type=secret,id=.env,target=/app/.env` (the `WORKDIR` is `/app` at this point).

The entry point for the container is (currently) `devbox run`, so to replicate `devbox run jules` using this container you would execute `docker run jules:vn7.9 jules`. I will probably change this soon (having `devbox run jules` as the entry point makes debugging hard, but there's probably a very obvious workaround).

JULES still needs to load the namelists and inputs, and we did not include these in the container itself. To run the container you need to link the run directory and the namelists directory to the container filesystem. You can mount the run directory (assuming the namelists directory is below it) to an _unused_ location in the container filesystem (`/app/run` in this example).

```sh
cd examples/loobos
docker run -v "$(pwd)":/app/run jules:vn7.9 jules -d run run/config
```

It will speed things up if the directory being linked is not too large, i.e. if the run directory (`examples/loobos` above) only contains the necessary inputs and namelists, and not a bunch of other stuff. 

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
