# Official image for Enonic XP

# Usage

Set environments in `.env` file, then push to GitHub.
Automatic builds with GitHub Actions will build and push the image to the selected remote repo.

# Files

* `Dockerfile` is the XP image recipe
* `bin/*` contains scripts needed for the Dockerfile
* `docker-compose.yml` can be used for local image testing
* * `docker-compose --compatibility up --force-recreate --build`
* * Su pass is `pass`
* `.env` is used to set remote docker image registry and image name:tags
