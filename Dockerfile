# Build using `docker build --secret id=.env -t jules:vn7.9 .`

FROM jetpackio/devbox-root-user:latest

# Create structure of working dir (/devbox & /devbox/scripts)
RUN mkdir -p /devbox

# Set /devbox as the working directory for subsequent commands
WORKDIR /devbox

# Copy files to /devbox
COPY devbox.json devbox.lock setup.sh jules.sh .

# Install packages, run garbage collection & optimisations in nix-store
RUN devbox run -- hello && nix-store --gc && nix-store --optimise

# Checkout and build Jules vn7.9 (rev 30414)
RUN --mount=type=secret,id=.env,target=/devbox/.env \
    devbox run --env-file /devbox/.env setup -r 30414

# Create entry point to run jules automatically
ENTRYPOINT ["devbox", "run", "jules"]
