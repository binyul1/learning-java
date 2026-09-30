# Java DevOps Demo

A small Spring Boot web application used to demonstrate a VM-based, Docker, and GitHub Actions deployment workflow. The root endpoint returns `Hello from Java DevOps Demo!`.

## End-to-end workflow

The automated pipeline is defined in `.github/workflows/ci.yaml`. It runs when code is pushed to the `main` branch. The build and deploy jobs run on GitHub Actions self-hosted runners.

### 1. Start the Vagrant VM

If you use Vagrant to host your self-hosted runner, go to the directory containing your `Vagrantfile` and start the VM:

```sh
vagrant up
vagrant status
```

Connect to it with `vagrant ssh` if you need to configure or inspect the machine. The Vagrantfile is not included in this repository, so the VM provider, forwarded ports, installed packages, and runner setup depend on your Vagrant configuration. The VM (or another self-hosted runner) must be online and registered with the GitHub repository before a workflow can run. It also needs Docker Engine and the Docker Compose plugin, and the runner user needs permission to run Docker commands.

### 2. Configure GitHub Actions

In the repository's GitHub settings, configure the `test` environment and these Actions secrets:

- `DOCKER_USERNAME`: Docker Hub account used for the image name and registry login.
- `DOCKER_PASSWORD`: Docker Hub password or access token used to publish and pull images.

The workflow names the image `${DOCKER_USERNAME}/learning-java`. Keep the self-hosted runner available for both jobs. The build job installs Maven with `apt-get`, so its runner must also allow that installation command to run with `sudo`.

### 3. Push a change to `main`

Commit and push your changes to `main`. The `build` job then:

1. Checks out the repository.
2. Sets up Temurin Java 17 and Maven dependency caching.
3. Installs Maven and prints the Java and Maven versions.
4. Runs `mvn clean package`, producing `target/java-devops-demo-1.0.0.jar`.
5. Logs in to Docker Hub using the configured secrets.
6. Builds the image from `Dockerfile` and pushes three tags: `latest`, the full Git commit SHA, and the GitHub run number.

The Dockerfile uses a Java 17 runtime image, copies the packaged JAR into `/app`, and starts it on port 8080.

### 4. Deploy with Docker Compose

After the build succeeds, the `deploy` job checks out the repository and logs in to Docker Hub. It sets `IMAGE_TAG` to the full commit SHA, then runs:

```sh
docker compose pull
docker compose up -d --remove-orphans
docker compose ps
```

`compose.yaml` uses `${IMAGE_NAME}:${IMAGE_TAG:-latest}`. The workflow supplies `IMAGE_NAME` from `DOCKER_USERNAME` and `IMAGE_TAG` from the commit SHA, so Compose pulls the exact image built for that push. The app is published on port 8080, and Compose is configured to restart it unless it is stopped.

Check the `deploy` job's `docker compose ps` output, then open `http://<runner-host>:8080/` (or `http://localhost:8080/` from the VM) to verify the greeting. Port 8080 must be reachable through any VM port forwarding and host firewall rules.

### 5. Stop the app or VM

Stop the Compose service on the deployment host with:

```sh
docker compose down
```

To stop, but keep, the Vagrant VM, run `vagrant halt` from the directory containing the Vagrantfile.

## Run locally

Requirements: Java 17 and Maven.

```sh
mvn clean package
java -jar target/java-devops-demo-1.0.0.jar
```

Open <http://localhost:8080/> to see the greeting.

## Run with Docker Compose locally

Requirements: Java 17, Maven, Docker Engine, and Docker Compose.

```sh
mvn clean package
docker build -t java-devops-demo:latest .
IMAGE_NAME=java-devops-demo docker compose up -d
```

Open <http://localhost:8080/>. Stop the container with `docker compose down`.