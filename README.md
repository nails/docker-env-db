# Docker Environment: Database

These Dockerfiles build a MySQL database container. By default a databases `dev` and `testing` are created and `root` has a random password generated.

## Tags

| Tag | MySQL | Platforms |
|---|---|---|
| `nails/docker-env-db:mysql-8.0`, `nails/docker-env-db:latest` | 8.0.46 | `linux/amd64`, `linux/arm64` |
| `nails/docker-env-db:mysql-5.7` | 5.7.32 | `linux/amd64` only (upstream `mysql:5.7` has no arm64 build) |

## Building

Images are built with `docker buildx` and pushed to Docker Hub as multi-arch tags, so `mysql-8.0` works on Apple Silicon Macs and x86 servers. Run it from either kind of machine (the non-native architecture is emulated, so it is slower):

```bash
bin/build.sh              # build and push everything
bin/build.sh mysql80      # just mysql-8.0 / latest
bin/build.sh mysql57      # just mysql-5.7
```

The script pushes as it builds and then checks every expected platform is in each published tag. Do **not** run `docker push nails/docker-env-db`: it pushes single-architecture images from your local store over the multi-arch tags.

To test changes on your own machine without pushing, build for your architecture only:

```bash
LOCAL=1 bin/build.sh mysql80
```

### Upgrading the MySQL version

The `mysql-8.0` tag is used by existing servers with existing data volumes. When a server rebuilds on a newer MySQL, the server upgrades its data directory automatically on first start, and **that cannot be rolled back**. Pin an exact upstream version in `mysql80/Dockerfile`, and make sure servers have a recent backup before publishing a new one.
