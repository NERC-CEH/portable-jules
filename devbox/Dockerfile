FROM jetpackio/devbox-root-user:latest

# Copy files to container
COPY devbox.json devbox.lock .
COPY scripts/hello.sh \
     scripts/setup.sh \
     scripts/build.sh \
     scripts/jules.sh \
  .

RUN mv devbox.json devbox.lock hello.sh setup.sh build.sh jules.sh /root/ && \
  chown -R root:root /root/*

# Install packages, run garbage collection & optimisations in nix-store
RUN cd /root/ && devbox run -- bash hello.sh && nix-store --gc && nix-store --optimise

# Checkout Jules vn7.9 (rev 30414)
RUN --mount=type=secret,id=.env,target=/root/.env \
    cd /root && devbox run --env-file /root/.env bash /root/setup.sh 30414

# Build Jules
RUN cd /root/ && devbox run bash /root/build.sh

# Create entry point
ENTRYPOINT ["devbox", "run"]
CMD ["bash", "/root/jules.sh"]
