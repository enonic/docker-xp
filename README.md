# Official image for Enonic XP

# Usage
Set environments in `env` file

After setting env, use:
```
./push-to-registry.sh 
```

# Files 
* Dockerfile is the XP image recipe
* Launcher.sh is needed for the Dockerfile
* docker-compose.yaml can be used for local image testing
* * docker-compose build && docker-compose up -d
* env is used to set remote docker image registry and image name:tags
* ./push-to-registry.sh is a script used to publish files to a repo
