## Current implementation of R/RStudio/VSCode with Docker

- [Colin FAY: An Introduction to Docker for R Users ](https://colinfay.me/docker-r-reproducibility/)
- [The Rocker Project Docker Containers for the R Environment](https://rocker-project.org/)

My current approach is to create a Docker image as a drop-in replacement for a classical local installation of R/RStudio. This image contains _all_ packages and their dependencies I ever need when working with R on my Desktop. (This might not be the cleanest approach, but I currently don't want to be bothered managing multiple containers for my different use cases. At the same time, I want to prevent wrecking my local R/RStudio setup *again*, and by using containers I can prevent this.)



### Docker with: R

- My main dockerfile is located here: [dockerfiles/Dockerfile-sandbox](dockerfiles/Dockerfile-sandbox), (locally: `/home/nils/ownCloud/System-Administration/dockerfiles/Dockerfile-sandbox`)
- To install more R-Packges, I simply extend this Dockerfile with additional lines of `RUN install2.r --error --skipinstalled name-of-rpackage`
- Create a *docker-image* from this file by running `sudo docker build -f Dockerfile-sandbox -t sandbox .` (note the `.`)

### Docker with: RStudio

Running RStudio:
- Run `rstudio-docker` in the command line to invoke the *Helper script* (see chapter `Helper Script` below)
- Alternatively (if the helper script does not work, I use the following code:
  
      sudo docker run --rm  -e DISABLE_AUTH=true -e ROOT=true -p 8787:8787 -v $(pwd):/home/rstudio/ sandbox

  - `--rm`: remove the container once I close it
  - `-e DISABLE_AUTH=true`: don't ask for a password to use rstudio
  - `-e ROOT=true`: add non-root user to the `sudoers` group, so that you can run `root` commands inside the docker. Note that if you have disabled authentication and not specified a password, the password to use `sudo` as the `rstudio` user will also be `rstudio` (see [here](https://www.rocker-project.org/use/managing_users/))
  - `-p 8787:8787`: use port `8787`
  - `-v $(pwd):/home/rstudio/` Mount the current working directory to my home directory in the container (`/home/rstudio/`)

### Docker with: VSCode

- [R in Visual Studio Code](https://code.visualstudio.com/docs/languages/r)
- Eric Nantz (Shiny Developer Series) shares his R-VSCode-docker setup:
  - https://www.youtube.com/live/4wRiPG9LM3o?feature=share
  - https://github.com/rpodcast/r_dev_projects

I'm trying to move more toward VSCode for various reasons. Combined with using docker only, this wasn't trivial. VSCode seemed to be designed for using separate docker images on each project (which of course makes a lot of sense). To use VSCode with my `sandbox` docker image I simply need to include a `.devcontainer/devcontainer.json` file in my project containing the following information:

```
{
    "image": "sandbox",
    "customizations": {
      // Configure properties specific to VS Code.
      "vscode": {
        // Set *default* container specific settings.json values on container create.
        "settings": { 
          "r.bracketedPaste": true,
          "r.plot.useHttpgd": true,
          "[r]": {
            "editor.wordSeparators": "`~!@#%$^&*()-=+[{]}\\|;:'\",<>/?"
          }
        },
        
        // Add the IDs of extensions you want installed when the container is created.
        "extensions": [
          "reditorsupport.r",
          "rdebugger.r-debugger",
          "ritwickdey.LiveServer",
          "quarto.quarto"
        ]
      }
    }
  }
```


Helper script:

I also created a helper script to make it very easy and fast to work with vscode projects with docker and r in an arbitrary folder. In `/usr/local/bin` I created two files: 

1. a devcontainer.json file containing the content above
2. a script (see below) named `code-r-docker` to:
  1. create a `.devcontainer` folder
  2. copy devcontainer.json from `/usr/local/bin` to the newly created folder above
  3. start vscode in the current folder 


```sh
#!/bin/bash

mkdir .devcontainer
cp /usr/local/bin/devcontainer.json .devcontainer/

code .
```

Additionally, I installed the libraries `languageserver` and `httpgd` in `sandbox` (`RUN install2.r --error --skipinstalled languageserver httpgd`)

## Custom images

You can extend existing docker images (from docker.io) with your own libraries by creating a file called `Dockerfile` (no extension) with the following information:

- `FROM` a base image hosted on docker.io
- `RUN` a bash command which gets executed when creating the image
- `CMD` a bash (?) command which gets executed when creating the container


Note: 
- `RUN`
  - there can be multiple `RUN` instructions in a `Dockerfile` ([more information](https://docs.docker.com/engine/reference/builder/#run))
  - **R**ocker images provide a few utility functions to extend images, including the littler scripts which provide a concise syntax for installing packages in Dockerfiles, e.g.`RUN install2.r pkg1 pgk2 pkg3 ...`. ([more information](https://www.rocker-project.org/use/extending/))
  - my personal observation: to successfully extend my container, I can simply append `RUN` lines to my `Dockerfile`. Re`build`ing the image will overwrite the old Docker image (if I use the same name) and will only take the amount of time needed to run the new line.
- there can only be one `CMD` instruction in a `Dockerfile` ([more information](https://docs.docker.com/engine/reference/builder/#cmd))



## Manage Docker as a non-root user

All docker commands need root privileges. To manage docker as non-root user, run the following lines (from [here](https://docs.docker.com/engine/install/linux-postinstall/)). I implemented this to run [docker with VScode](https://code.visualstudio.com/docs/containers/overview).

```
grep docker /etc/group # added this later, to check if the group already exists. If it does, skip the next line
sudo groupadd docker
sudo usermod -aG docker $USER
newgrp docker 
docker run hello-world
```

- 2022-11-10: On a similar topic, but on a different level: Currently, all files created within docker [are owned by root](https://unix.stackexchange.com/a/627028/487245), making it somewhat tedious to work with the files outside the container (I need to change the owner of said files using `sudo chown $USER filename`  or `sudo chown nils filename`). I thought I could solve this by simply adding [`"remoteUser": "nils"` to my devcontainer.json file](https://code.visualstudio.com/remote/advancedcontainers/add-nonroot-user), but doing this throws an error after restarting the container. 
- 2023-02-10: [Eric Nantz](https://github.com/rpodcast/r_dev_projects) adds the following line to the Dockerfile, maybe this will help? `USER $USERNAME`







## Shared volumes

(from [here](https://www.rocker-project.org/use/shared_volumes/))

To share a volume with the host we use the -v or --volume flag. Simply indicate the location on the host machine on the left side of `:`, and indicate the location on the container to the right. For instance:

```
docker run --rm  \ 
  -e PASSWORD=yourpassword \
  -p 8787:8787 \
  -v /Users/bob/Documents:/home/rstudio/Documents \
  rocker/rstudio
```

## Helper Script

Saving the following lines as `/usr/local/bin/rstudio-docker` allows me to run `rstudio-docker` from anywhere to start an rstudio instance in that working directory. 


Note:
no sudo is required since I enabled docker to run without root
- the "&" runs the second line in a new session, since the first session is blocked docker
- todo: make the port number (before ":" in "-p") a parameter with a default value ([must be >1023*](https://sbamin.com/blog/2016/02/running_rstudio_in_docker_environment/))

```
docker run --rm  -e DISABLE_AUTH=true -e ROOT=true -p 8787:8787 -v $(pwd):/home/rstudio/ sandbox & 
python3 -mwebbrowser localhost:8787  
```

Advanced script (Experimental )

- Adds `--port` as a named argument [check this blogpost](https://www.brianchildress.co/named-parameters-in-bash/)
- checks if the port is available [here](https://stackoverflow.com/a/15886087/4139249) and [here](https://stackoverflow.com/a/9463554/4139249)

```
#!/bin/bash

port=${port:-8787}

while [ $# -gt 0 ]; do

   if [[ $1 == *"--"* ]]; then
        param="${1/--/}"
        declare $param="$2"
   fi

  shift
done

if [ $port -gt 1023 ]; then
   ava=`nc -z localhost $port; echo $?`
else
   echo "Error: Port must be > 1023"
fi

if [ $ava -eq 1 ]; then
   echo "port is available. Starting RStudio now";
   docker run --rm  -e DISABLE_AUTH=true -e ROOT=true -p $port:8787 -v $(pwd):/home/rstudio/ sandbox &
   python3 -mwebbrowser localhost:$port
else
   echo "Error: port $port is not available. Choose a different port with the --port option"
fi
```




## RStudio without authentication

(from [here](https://www.rocker-project.org/use/managing_users/))

If you are certain you are running in a secure environment (e.g. not a publicly accessible server such as AWS instance), you can disable authentication for RStudio by setting an environmental variable `DISABLE_AUTH=true`, e.g.:

```
docker run --rm \
  -p 127.0.0.1:8787:8787 \
  -e DISABLE_AUTH=true \
  rocker/rstudio
```





## Cleaning up stale instances

(from [here](https://www.rocker-project.org/use/managing_containers/))

Most of the examples shown here (on rocker-progect.org) include the use of the `--rm` flag, which will cause this container to be removed after it has exited. By default, a container that is stopped (i.e. exited from) is not removed, and can be resumed later using docker start, be saved as a new docker image, or have files copied from it to the host. However, most of the time we just forget about these containers, though they are still taking up disk space. You can view all stopped as well as running containers by using the `-a` flag to `docker ps` (commands must be run as root, i.e. prepend `sudo -i`):

```
docker ps -a                     # view all stopped and running containers
docker rm -v $(docker ps -a -q)  # remove all stopped containers

```



## Docker and Git

One way to work with GitHub within a container is to share the system wide ssh keys with the container. For this reason, I added the following line to my `rstudio-docker` file (which is located here: `/usr/local/bin/`):

```diff
-   docker run --rm  -e DISABLE_AUTH=true -e ROOT=true -p $port:8787 -v $(pwd):/home/rstudio/ sandbox &
+   docker run --rm  -e DISABLE_AUTH=true -e ROOT=true -p $port:8787 -v $(pwd):/home/rstudio/ -v /home/${USER}/.ssh:/home/rstudio/.ssh sandbox &
```

(I found this [here](https://github.com/rpodcast/r_dev_projects/blob/4075b01918ce08334d2c6e2dfd94b0e1b4fa477c/.devcontainer/docker-compose.yml#L31), but replace the second `$USER with rstudio)


