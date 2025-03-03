<p align="center"><img src="logo_Landis_Docker_Apptainer.svg" width="500"></p>

<h1 align="center">LANDIS-II Docker and Apptainer</h1>

Ressources to create and use a Docker Image and an Apptainer containing the [LANDIS-II model](https://www.landis-ii.org/) and its extensions, for use on almost any environment, including supercomputing clusters.

## 🐋 What is Docker ?

Docker is an open-source platform designed for creating, deploying, and managing applications using what are called "containers".

Containers can be seen as a kind of special file that contain an entire computer environment, including an OS (like Linux or Windows) and as many programs, packages or libraries as you want to install in it.

Docker containers are created, managed and run on your computer using the Docker Engine (which you have to install), and can be interacted with easily. But when run, what's hapenning in the container is separated from what goes on in the rest of your computer. However, you can make some files from your computer available in the container (like LANDIS-II scenario files), as we'll see later in this readme.

Using a Docker container to run LANDIS-II has many advantages :

- It's easy to install (see below; one program to install in your computer + one command in a terminal)
- You will be able to run LANDIS-II on any plateform (Mac OS, Windows, Linux, etc.) with no compatibility issue.
    - The only exception is for High Performance Computing (HPC) environment, like supercomputing clusters. In that case, use Apptainer (see below)
- Your LANDIS-II simulations will be highly replicable, since they will not depend on the environment of your own work computer (e.g. R and Python packages you have, etc.); but only on what you define in the Dockerfile (the file that will generate your Docker container)
- You can easily deploy different LANDIS-II environments (sets of extensions + R or Python packages) on your computer without having conflicts or problems between them.
- **You ensure that LANDIS-II will always have the right dependencies to function**. 


To learn more about Docker, you can check [one of the many videos explaining the concept](https://youtu.be/_dfLOzuIg2o).

## 📦 What's an Apptainer ?

[Apptainer](https://apptainer.org/) (formerly called "Singularity") is a program that creates "containers" similar to Docker. These containers contain an entire operating system (OS) like Ubuntu, along with every program or dependencies you might want to install in it. As for Docker containers, and Apptainer can still edit and modify files that are "outside" of the Apptainer if they are made available inside of the Apptainer through a special command. See below for more.

The differences between Docker containers and Apptainer are very technical; for example, Docker has a "layering" system that allows different Docker containers running on the same machine to use the same files that they share with each other. But the only thing that will certainly matter to you as a LANDIS-II user is that Apptainers are made to be run on a High Performance Computing environment, where the security standards are much greater, and where Docker containers are often forbiden from use for different reasons.

The biggest advantage of Apptainers is that just like Docker Containers, they will ensure that LANDIS-II always have all of the necessary dependencies to run anywhere, especially on supercomputing clusters. This is crucial, as supercomputing clusters tend to restrain the programs/modules/packages/dependencies one can load inside your session. This can create hair-pulling scenarios where any update of the global environment in the clusters breaks your LANDIS-II installation, as it cannot access the right dependencies anymore. 

> 💡 While Docker containers are often forbiden on High Performance Computing environments, they are generaly safe to use on your computer. They can be used, like almost any program, to hurt your computer; especially if they contain older version of packages or programs that contain known vulnerabilities, and if they are run in ways that make them accessible to attakers. In case of doubt, use Docker Scout to analyze a container before running a container. You can find more information about the security of Docker Containers [here](https://www.docker.com/blog/container-security-and-why-it-matters/). **While several vulnerabilities exist in the Docker containers that you can create with this repository, they should not cause problems to your computer as long as you run the containers for LANDIS-II simulations and with LANDIS-II scenario files that you trust.**

## ⚙ How to use

> 💡 If you want to use LANDIS-II on a HCP environment (e.g. supercomputing clusters), then you can simply download one of the Apptainer files available in the [Releases](https://github.com/LANDIS-II-Foundation/Tool-Docker-Apptainer/releases) section of this repository and follow the instruction below to run it with the right command. However, we recommand that you familiarize yourself with the rest of the instructions to learn how these files are made, so that you can edit and customize them for your own research purposes.

### 📦 Building the docker image containing LANDIS-II

> 💡 A Docker image is simply a "template" to initialize a Docker container. You can create many Docker Containers from one Docker image. Imagine that the Docker image is a blueprint for a house or a "demo" house, while Docker containers are houses where people actually live. You first need to make the Docker image before creating a Docker container. 

- Download [Docker Desktop](https://www.docker.com/) on your computer. You can also install Docker through a command prompt if you are on Linux.
    - On Windows, Docker Desktop will ask you by default to be integrated with what is called "WSL", the Windows Subsystem for Linux. The WSL can be seen as a "Linux emulator" for Windows, and it can help for a lot of things. It's recommanded that you use the WSL integration; however, you might need to enable the WSL before starting Docker Desktop, or you'll get an error at launch. To enable the WSL, simply open a Powershell command prompt and use `wsl --install` as a command. Restart your computer, and all should be good.
- Launch Docker Desktop. This will start the Docker Engine on your computer.
- Download the contents of this repository; especially the folders `Clean_Docker_LANDIS-II_7_AllExtensions` and `Clean_Docker_LANDIS-II_8_AllExtensions`.
- Open a terminal on your computer (e.g. a Powershell command prompt if you're on Windows) and change your working directory until you get to `Clean_Docker_LANDIS-II_7_AllExtensions` or `Clean_Docker_LANDIS-II_8_AllExtensions`, depending on which version of LANDIS-II you want to use. v8 is more advanced, but might have some errors and bugs, and not all extensions are available for it yet. 
- Use the command `docker build -t landis_ii .` to tell Docker to build a Docker image containing LANDIS-II based on the instructions of the file named `Dockerfile` in the folder.
	> 💡 In this command, `landis_ii` is simply the name we will give to our image. You can change this name to whatever is best for you. 
    > 💡 You can read the `Dockerfile` with any text editor. You will see that it contains a set of Linux commands to download the different programs and packages necessary to run LANDIS-II in the container, which uses a Linux environment (Ubuntu). You will be able to add commands to customize your Docker image, and the containers you will create from it.
	
### 📝 (Optional) Customizing the docker image image with R packages, Python packages, or anything else

The Docker image we have created contains all of the files necessary to run LANDIS-II in the Ubuntu (linux) environment of the image. But you might want to add more things that will be necessary for your study, like R or Python packages for analyzing your outputs. **Everything you put in the Docker image will be easily available to other research groups looking to replicate, improve or update your methodology if you share the `Dockerfile` you used to create it.** As such, we recommand that you take full advantage of it. The sky is the limit !

You can edit the `Dockerfile` with any text editor. You can easily add commands to the build command using the RUN instruction, as you will see it often in the Dockerfiles of this repository. For anything else, please see the [Dockerfile syntax](https://docs.docker.com/reference/dockerfile/).

Once you have edited the `Dockerfile`, you can run the build process again to create a new version of it.

> 💡 Let's say you want to install Python and a couple of packages so that you can process your LANDIS-II outputs once your scenario has done running. You can add the following to your Dockerfile :
> `RUN pip install numpy rasterio pandas`

> 💡 You can share the `Dockerfile` that you have created for your own study to ensure maximum replicability ! The `Dockerfile` is very light as it is only a text file, and can be shared in any way you like.

### ⚡ Running a Docker container based on the image

There are several ways to run a Docker container :

- You can run it "interactively" via the `-it` argument, which will allow you to interact with your container in your command prompt. From there, you can look at the files that are inside the container, run a LANDIS-II scenario, etc.
- Or, you can run it in a non-interactive way and specify a couple of commands to execute. When the commands are done (or if they fail), the container will simply shut down. 

In both cases, you can create a "bind", which will allow your container to access and edit files that are on your computer, outside of the container. This is most likely what you will want to do to run a LANDIS-II simulation on your computer; the container will then be able to read the scenario files, run LANDIS-II, and create the output files in the same folder.

To run an interactive Docker container with a bind, use the following command :

```shell
docker run -it --mount type=bind,src="<SCENARIO_FOLDER_FULL_PATH_ON_COMPUTER>",dst=/scenarioFolder <LANDIS_DOCKER_IMAGE_NAME>
```

- `docker run` is used to create a container from a Docker image present on your computer
- `-it` will run the container interactively
- `--mount type=bind,src="<SCENARIO_FOLDER_FULL_PATH_ON_COMPUTER>",dst=/scenarioFolder` will bind make the folder containing LANDIS-II scenario files on your computer available inside the container, at the path `/scenarioFolder`. Simply replace `<SCENARIO_FOLDER_FULL_PATH_ON_COMPUTER>` with the full path to the folder on your compute (for example, `C:\Users\JohnDoe\LANDIS-II_Simulation`).
- `<LANDIS_DOCKER_IMAGE_NAME>` is simply the name of the Docker image we have built earlier (for example, `landis_ii).

To run a non-interactive Docker container with a bind, use :

```shell
docker run --mount type=bind,src="<SCENARIO_FOLDER_FULL_PATH_ON_COMPUTER>",dst=/scenarioFolder <LANDIS_DOCKER_IMAGE_NAME> /bin/sh -c "<COMMAND 1> && <COMMAND 2>"
```

- Here, `/bin/sh -c "<COMMAND 1> && <COMMAND 2>` allow use to define the commands we want to run once the container is running. You can add more commands with the `&&` symbol.

### 🌳 Launching a LANDIS-II simulation through the container

The Docker containers created with the Dockerfiles present in this repository will be running in an Ubuntu (linux) environment.

As such, the command to launch LANDIS-II in the container will be a bit different.

To launch a LANDIS-II simulation from inside the container, you will need to change the workind directory to the folder containing your scenario files, and then run :

```shell
dotnet $LANDIS_CONSOLE scenario.txt
```

- `dotnet` is the linux program that allows us to run LANDIS-II on linux, since it's coded in C# (a programming langage made by microsoft)
- `$LANDIS_CONSOLE` is an environment variable that contains the location of the LANDIS-II program in the container (in `/bin/LANDIS_Linux/build/Release/Landis.Console.dll`
- `scenario.txt` is the name of your scenario file.

As such, if you want to run LANDIS-II through an interactive container :

- Run the command `docker run -it --mount type=bind,src="<SCENARIO_FOLDER_FULL_PATH_ON_COMPUTER>",dst=/scenarioFolder <LANDIS_DOCKER_IMAGE_NAME>`
- In the interactive mode, use `cd` to change your workind directory to go into `/scenarioFolder` (or where you can access your scenario files through the bind)
- Once you are in the right folder, run `dotnet $LANDIS_CONSOLE scenario.txt`, and the scenario should run.

If you want to run the LANDIS-II scenario in an non-interactive container (usefull to automatize your simulations), here is the full command :

```shell
docker run --mount type=bind,src="<SCENARIO_FOLDER_FULL_PATH_ON_COMPUTER>",dst=/scenarioFolder <LANDIS_DOCKER_IMAGE_NAME> /bin/sh -c "cd /scenarioFolder && dotnet $LANDIS_CONSOLE scenario.txt"
```

Simply make sure that the command `cd /scenarioFolder` goes where your `scenario.txt` file is located. If it's in a subfolder, change it to `cd /scenarioFolder/subFolder`.

### 📦 (Optional) Building an apptainer file to use LANDIS-II on HCP environments (e.g. supercomputing clusters)

You can easily create an Apptainer file (in `.sif` format) from a Docker image to deploy on HCP environments.

- First, you need to install Apptainer (the program) on your computer. This can only be done in Linux. If you are on Windows, you can use the WSL that we installed with Docker Desktop (see above) to run an Ubuntu console on your Windows computer. Simply run `wsl -d Ubuntu` in a Powershell terminal. You can also create a Docker container that contains Apptainer. See [this repository](https://github.com/kaczmarj/apptainer-in-docker) for one.
- Then, you need to export your Docker image as an archive file. Use `docker save <NAME OF DOCKER IMAGE> -o <DOCKER ARCHIVE FILE NAME>.tar` in the terminal of your choice.
- Then, you need to use a Linux terminal with Apptainer installed, and change your working directory to go the folder containing your `.tar` docker archive file.
- End up by using this command : `apptainer build --fakeroot <NAME OF YOUR APPTAINER FILE>.sif docker-archive://<DOCKER ARCHIVE FILE NAME>.tar`. Simply edit the command to put the name of your files.
> ⚠ This compilation often takes a lot of RAM, and will fail if you do not have enough of it available ! If that's the case, you can download and use one of the `.sif` files available in the [Releases](https://github.com/LANDIS-II-Foundation/Tool-Docker-Apptainer/releases) section of this repository.

To use the apptainer on a HCP environment :

- Upload your LANDIS-II scenario files and your `.sif` apptainer file on your HCP environment.
- In the terminal you use to interact with your HCP environment, load the package `apptainer` (which should be available).
- Go to where your `.sif` files are located, and use the following command :

```shell
apptainer exec -C -B <FULL_PATH_TO_FOLDER_WITH_SCENARIO_FILE> <NAME OF YOUR APPTAINER FILE>.sif /bin/sh -c "cd <FULL_PATH_TO_FOLDER_WITH_SCENARIO_FILE> && dotnet $LANDIS_CONSOLE scenario.txt"
```

As you can see, the command is very similar to the one used with Docker.

- `apptainer` calls the `apptainer` package, which knows how to use your `.sif` file.
- `exec` tells the `apptainer` package that we are going to run commands inside the Apptainer.
- `-C` tells `apptainer` remove all of the folder binding that gets done automatically by apptainer. It will only bind the folders to the apptainer that we tell him to. The folder binding is essential : it's the process through which your Apptainer will become able to access files from outside the Apptainer file.
- `-B <FULL_PATH_TO_FOLDER_WITH_SCENARIO_FILE>` binds the folder containing your scenario files. Replace `<FULL_PATH_TO_FOLDER_WITH_SCENARIO_FILE>` with the **full, absolute path** to your scenario folder on your HCP environment (e.g. `/home/Klemet/LANDIS-II_Simulations/Simulation1`). These files will become accessible inside the Apptainer at the same path.
- `<NAME OF YOUR APPTAINER FILE>.sif` is simply the name of the Apptainer file.
-  `/bin/sh -c "... && ..."` is used to give several commands at once to do inside the Apptainer. These two commands (`cd` and `donet`) are described just below.
-  `cd <FULL_PATH_TO_FOLDER_WITH_SCENARIO_FILE>` is a the first command we launch while inside the Apptainer : we simply use it to go inside the folder containing your LANDIS-II scenario files, which are accessible inside the Apptainer thanks to `-B <FULL_PATH_TO_FOLDER_WITH_SCENARIO_FILE>` that we used before, which "binded" them inside it.
-  `dotnet $LANDIS_CONSOLE scenario.txt` is the final command we launch to launch the simulation.


## 🐛 Problem, issue or bug ?

- **I'm encountering an error when compiling the Docker image where it says that it fails to download from github (something like `error unexpected disconnect while reading sideband packet`). What should I do ?**

You're most likely using Windows; this error seems to be due to an oudated SSH library that deal with the encryption of connections. See [here](https://github.com/orgs/community/discussions/48568#discussioncomment-8510498) for more information. It seems like it can be solved by downloading the latest beta version of the SSH library of microsoft, by using the following command in a Powershell prompt :

```powershell
 winget install Microsoft.OpenSSH.Beta
```

- **I'm encountering an error when compiling the Docker image at the beginning of the process, where commands like `apt update` and `apt upgrade` are used. What should I do ?**
 
Most likely, this error is due the fact that the command returned an interactive prompt in the form of `Do you want to continue? [Y/n]Abort.`. Because Docker cannot answer this prompt, the command is aborder and returns an error. Simply change the command to something like `apt update -y` in your Dockerfile; the `-y` flag will confirm the prompt automatically for you.

- **I've got another error that is not indicated here ?**

Please head to the [LANDIS-II users group](https://www.landis-ii.org/users) if you have questions or issues !
