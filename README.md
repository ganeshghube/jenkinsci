# ProjectX


This Project has following question to solve using devops tools.

## Docker

Write a Dockerfile to run nginx version 1.19 in a container.

Choose a base image of your liking. The build should be security conscious 
and ideally pass a container image security test. [20 pts]

====================================================================================

Prerequisities:

For this project I choose a EC2 instance on Amazon with size t2.medium with 50Gib / volume

1) Execute yum update all command to make sure current OS is updated with latest patches.
```bash
yum update all
```
2) Created sudo user called install and setup a password to it with steps below.
```bash
sudo adduser install
passwd install
sudo visudo
```

2) Uncomment following line save the file.
```bash
%wheel  ALL=(ALL)       NOPASSWD: ALL
```

3) Execute below command to make install as sudo user.
```bash
sudo usermod -a -G wheel install
```

4) Install Docker using the following command: 
```bash
sudo yum install docker && sudo yum info docker
```
5) Add user to Docker group using command 
```bash
sudo usermod -a -G docker install
```
5) Enabled and started docker service with comand 
```bash
sudo systemctl enable docker.service && sudo systemctl start docker.service
```
6) Verify with following command 
```bash
sudo docker info && docker --version
```
