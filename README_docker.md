# Building & running docker containers

To build the container

```sh
docker build -f Dockerfile.user -t jules .
```

The following runs the Loobos example. Note that we need to mount the working directory to a location in the container filesystem (`app` here).

```sh
docker run -v "$(pwd)":/app jules -d /app/examples/loobos /app/examples/loobos/config
```
