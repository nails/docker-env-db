# Docker Environment: Database

These Dockerfiles build a MySQL database container. By default a databases `dev` and `testing` are created and `root` has a random password generated.

## Tags

- `nails/docker-env-db:mysql-8.0`, `nails/docker-env-db:latest`
- `nails/docker-env-db:mysql-5.7`

## Building

To compile and publish changes to these containers use the following commands:

```
docker build -t nails/docker-env-db:<tag> ./mysql<version>
docker push nails/docker-env-db
```