# Slurm on CentOS 7 Docker Image

[![Docker Build Status](https://img.shields.io/docker/build/giovtorres/docker-centos7-slurm.svg)](https://hub.docker.com/r/giovtorres/docker-centos7-slurm/builds/)
[![Docker Automated build](https://img.shields.io/docker/automated/giovtorres/docker-centos7-slurm.svg)](https://hub.docker.com/r/giovtorres/docker-centos7-slurm/)
[![Docker Pulls](https://img.shields.io/docker/pulls/giovtorres/docker-centos7-slurm.svg)](https://hub.docker.com/r/giovtorres/docker-centos7-slurm/)
[![](https://images.microbadger.com/badges/image/giovtorres/docker-centos7-slurm.svg)](https://microbadger.com/images/giovtorres/docker-centos7-slurm "Get your own image badge on microbadger.com")

This is an all-in-one [Slurm](https://slurm.schedmd.com/) installation.  This
container runs the following processes:

* slurmd (The compute node daemon for Slurm)
* slurmctld (The central management daemon of Slurm)
* slurmdbd (Slurm database daemon)
* munged (Authentication service for creating and validating credentials)
* mariadb (MySQL compatible database)
* supervisord (A process control system)

It also has the following Python versions installed, including the
corresponding -devel and -pip packages:

* Python 2.7
* Python 3.5
* Python 3.6
* Python 3.7
* Python 3.8

## Usage

There are multiple
[tags](https://hub.docker.com/r/giovtorres/docker-centos7-slurm/tags/)
available.  To use the latest available image, run:

```shell
docker pull giovtorres/docker-centos7-slurm:latest
docker run -it -h ernie giovtorres/docker-centos7-slurm:latest
```

The above command will drop you into a bash shell inside the container. Tini
is responsible for `init` and supervisord is the process control system . To
view the status of all the processes, run:

```shell
[root@ernie /]# supervisorctl status
munged                           RUNNING   pid 23, uptime 0:02:35
mysqld                           RUNNING   pid 24, uptime 0:02:35
slurmctld                        RUNNING   pid 25, uptime 0:02:35
slurmd                           RUNNING   pid 22, uptime 0:02:35
slurmdbd                         RUNNING   pid 26, uptime 0:02:35
```

In `slurm.conf`, the **ControlMachine** hostname is set to **ernie**. Since
this is an all-in-one installation, the hostname must match **ControlMachine**.
Therefore, you must pass the `-h ernie` to docker at run time so that the
hostnames match.

You can run the usual slurm commands:

```shell
[root@ernie /]# sinfo
PARTITION AVAIL  TIMELIMIT  NODES  STATE NODELIST
normal*      up 5-00:00:00      5   idle c[1-5]
debug        up 5-00:00:00      5   idle c[6-10]
```

```shell
[root@ernie /]# scontrol show partition
PartitionName=normal
   AllowGroups=ALL AllowAccounts=ALL AllowQos=ALL
   AllocNodes=ALL Default=YES QoS=N/A
   DefaultTime=5-00:00:00 DisableRootJobs=NO ExclusiveUser=NO GraceTime=0 Hidden=NO
   MaxNodes=1 MaxTime=5-00:00:00 MinNodes=1 LLN=NO MaxCPUsPerNode=UNLIMITED
   Nodes=c[1-5]
   PriorityJobFactor=50 PriorityTier=50 RootOnly=NO ReqResv=NO OverSubscribe=NO PreemptMode=OFF
   State=UP TotalCPUs=5 TotalNodes=5 SelectTypeParameters=NONE
   DefMemPerCPU=500 MaxMemPerNode=UNLIMITED
```

## Building

### Using Existing Tags

There are multiple versions of Slurm available, each with its own tag.  To build
a specific version of Slurm, checkout the tag that matches that version and
build the Dockerfile:

```shell
git clone https://github.com/giovtorres/docker-centos7-slurm
git checkout <tag>
docker build -t docker-centos7-slurm .
```

### Using Build Args

You can use docker's `--build-arg` option to customize the version of Slurm
and the version(s) of Python at build time.

To specify the version of Slurm, assign a valid Slurm tag to the `SLURM_TAG`
build argument:

```shell
docker build --build-arg SLURM_TAG="slurm-19-05-1-2" -t docker-centos7-slurm:19.05.1-2
```

To specify the version(s) of Python to include in the container, specify a
space-delimited string of Python versions using the `PYTHON_VERSIONS` build
argument:

```shell
docker build --build-arg PYTHON_VERSIONS="3.6 3.7" -t docker-centos7-slurm:py3
```

## Using docker-compose

The included docker-compose file will run the cluster container in the
background.  The docker-compose file uses data volumes to store the slurm state
between container runs.  To start the cluster container, run:

```shell
docker-compose up -d
```

To execute commands in the container, use `docker exec`:

```shell
docker exec dockercentos7slurm_slurm_1 sinfo
PARTITION AVAIL  TIMELIMIT  NODES  STATE NODELIST
normal*      up 5-00:00:00      5   idle c[1-5]
debug        up 5-00:00:00      5   idle c[6-10]

docker exec dockercentos7slurm_slurm_1 sbatch --wrap="sleep 10"
Submitted batch job 27

docker exec dockercentos7slurm_slurm_1 squeue
            JOBID PARTITION     NAME     USER ST       TIME  NODES NODELIST(REASON)
            27    normal     wrap     root  R       0:07      1 c1
```

To attach to the bash shell inside the running container, run:

```shell
docker attach dockercentos7slurm_slurm_1
```

Press `Ctrl-p,Ctrl-q` to detach from the container without killing the bash
process and stopping the container.

To stop the cluster container, run:

```shell
docker-compose down
```

## Testing Locally

[Testinfra](https://testinfra.readthedocs.io/en/latest/index.html) is used to
build and run a Docker container test fixture. Run the tests with
[pytest](https://docs.pytest.org/en/latest/):

```shell
pytest -v
```

## Running repo2docker locally

Instructions are from [here](https://github.com/jupyterhub/repo2docker#prerequisites)

1. Install Docker if you do not have it already
2. Install Python 3.6.+ 
3. Run:
```shell
pip install jupyter-repo2docker
```
4. Start Docker if not running already
5. Run:
```shell
jupyter-repo2docker https://github.com/AaltoSciComp/repo2docker-slurm
```
6. Go to the url when you see something like:
```shell
Copy/paste this URL into your browser when you connect for the first time, to login with a token:
http://127.0.0.1:54272/?token=5615b2e23d8a21db9f2623038123390832a33e2d0eb7cf49
```

In the Jupyter view, on the right-hand side click "New" -> "Terminal" to launch shell where you are able to run Slurm commands.
