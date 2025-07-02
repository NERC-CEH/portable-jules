FROM jetpackio/devbox-root-user:latest AS devbox-jules

# Copy files to container
COPY devbox.json /app/devbox.json
COPY devbox.lock /app/devbox.lock
COPY scripts /app/scripts

# Set /app as the working directory for subsequent commands
WORKDIR /app

# Install packages
RUN devbox install

# Run garbage collection & optimisations in nix-store
RUN devbox run -- nix-store --gc && nix-store --optimise

FROM devbox-jules

# Checkout Jules vn7.9 (rev 30414)
RUN --mount=type=secret,id=.env,target=/app/.env \
    devbox run --env-file /app/.env setup 30414

# Build Jules
RUN devbox run build

# Create entry point
ENTRYPOINT ["devbox", "run"]
