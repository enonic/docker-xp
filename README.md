# Official image for Enonic XP

# Usage

Set environments in `.env` file. After setting `.env`, use:

```bash
./push-to-registry.sh 
```

You need to be authorized to push to a remote repo:
* For GCR.io you need to use `gcloud` tool from Google and connect to the project
* For Docker hub you need to use `docker login` with your credentials

# Files

* `Dockerfile` is the XP image recipe
* `bin/*` contains scripts needed for the Dockerfile
* `docker-compose.yml` can be used for local image testing
* * `docker-compose --compatibility up --force-recreate --build`
* * Su pass is `pass`
* `.env` is used to set remote docker image registry and image name:tags
* `./push-to-registry.sh` is a script used to publish files to a repo
