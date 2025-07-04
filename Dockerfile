# Build using `docker build --secret id=.env -t jules:vn7.9 .`

FROM jetpackio/devbox-root-user:latest AS devbox-jules

# Set /devbox as the working directory for subsequent commands
WORKDIR /devbox

# Copy files to container
COPY devbox/devbox.json \
     devbox/devbox.lock \
 ./
COPY devbox/scripts/hello.sh \
     devbox/scripts/setup.sh \
     devbox/scripts/build.sh \
     devbox/scripts/jules.sh \
 ./scripts/

# Install packages, run garbage collection & optimisations in nix-store
RUN devbox run -- hello && nix-store --gc && nix-store --optimise

FROM devbox-jules

# Set /devbox as the working directory for subsequent commands
WORKDIR /devbox

# Checkout Jules vn7.9 (rev 30414)
RUN --mount=type=secret,id=.env,target=/devbox/.env \
    devbox run --env-file /devbox/.env setup 30414

# Build Jules
RUN devbox run build

# Create entry point
ENTRYPOINT ["devbox", "run"]
