FROM jetpackio/devbox-root-user:latest AS devbox-jules

# Set /devbox as the working directory for subsequent commands
WORKDIR /devbox

# Copy files to container
COPY devbox/devbox.json .
COPY devbox/devbox.lock .
COPY devbox/scripts .

# Install packages
RUN devbox install

# Run garbage collection & optimisations in nix-store
RUN devbox run -- nix-store --gc && nix-store --optimise

FROM devbox-jules

# Checkout Jules vn7.9 (rev 30414)
RUN --mount=type=secret,id=.env,target=/devbox/.env \
    devbox run --env-file /devbox/.env setup 30414

# Build Jules
RUN devbox run build

# Create entry point
ENTRYPOINT ["devbox", "run"]
