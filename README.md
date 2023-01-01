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

7) Create a docker file and build an image as Smallest distroless nginx container

############################################################################################

```bash
FROM debian:buster-slim AS build


WORKDIR /var/www/nginx-distroless
COPY . /var/www/nginx-distroless

RUN echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections

#Install necessary libraries and dependency to compile nginx.
RUN apt-get update && apt-get install -y gcc make libc-dev libxslt1-dev libxml2-dev zlib1g-dev libpcre3-dev libbz2-dev libssl-dev autoconf wget lsb-release apt-transport-https ca-certificates

#Download nginx version 1.19.0. You can try other version too.
RUN wget http://nginx.org/download/nginx-1.19.0.tar.gz && tar xf nginx-1.19.0.tar.gz

#start compiling nginx and install it in the build image.
RUN cd nginx-1.19.0 && \
./configure --prefix=/etc/nginx --sbin-path=/usr/sbin/nginx --conf-path=/etc/nginx/nginx.conf \
--error-log-path=/var/log/nginx/error.log --http-log-path=/var/log/nginx/access.log \
--pid-path=/var/run/nginx.pid --lock-path=/var/run/nginx.lock \
--http-client-body-temp-path=/var/cache/nginx/client_temp --http-proxy-temp-path=/var/cache/nginx/proxy_temp \
--http-fastcgi-temp-path=/var/cache/nginx/fastcgi_temp --http-uwsgi-temp-path=/var/cache/nginx/uwsgi_temp \
--http-scgi-temp-path=/var/cache/nginx/scgi_temp \
--with-cc-opt="-O2 -g -pipe -Wall -Wp,-D_FORTIFY_SOURCE=2 -fexceptions -fstack-protector-strong --param=ssp-buffer-size=4 -grecord-gcc-switches -m64 -mtune=generic -fPIC" \
--with-ld-opt="-Wl,-z,relro -Wl,-z,now -pie" \
--user=nonroot --group=nonroot --with-compat --with-file-aio --with-threads --with-http_addition_module \
--with-http_auth_request_module --with-http_dav_module --with-http_flv_module --with-http_gunzip_module \
--with-http_gzip_static_module --with-http_mp4_module --with-http_random_index_module \
--with-http_realip_module --with-http_secure_link_module --with-http_slice_module \
--with-http_stub_status_module --with-http_sub_module --with-http_v2_module --with-http_degradation_module \
--with-pcre --with-pcre-jit --with-http_ssl_module && \
make && \
make install

#Let's create some necessary folders for nginx.
RUN mkdir -p /var/cache/nginx/ && mkdir -p /var/lib/nginx && mkdir -p /etc/nginx/conf.d/

#Grab the distroless static container.
FROM gcr.io/distroless/static

#Set the container timezone as UTC.
ENV TZ="UTC"
COPY --from=build /var/log /var/log
COPY --from=build /var/cache/nginx /var/cache/nginx
COPY --from=build /var/run /var/run

#Copy the nginx configuration and binary from build image.
COPY --from=build /etc/nginx /etc/nginx
COPY --from=build /usr/sbin/nginx /usr/bin/nginx

#Copy the necessary dependencies from build image to run nginx properly in static container.
COPY --from=build /lib/x86_64-linux-gnu/libdl.so.2 /lib/x86_64-linux-gnu/
COPY --from=build /lib/x86_64-linux-gnu/libpthread.so.0 /lib/x86_64-linux-gnu/
COPY --from=build /lib/x86_64-linux-gnu/libcrypt.so.1 /lib/x86_64-linux-gnu/
COPY --from=build /lib/x86_64-linux-gnu/libpcre.so.3 /lib/x86_64-linux-gnu/
COPY --from=build /usr/lib/x86_64-linux-gnu/libssl.so.1.1 /usr/lib/x86_64-linux-gnu/
COPY --from=build /usr/lib/x86_64-linux-gnu/libcrypto.so.1.1 /usr/lib/x86_64-linux-gnu/
COPY --from=build /lib/x86_64-linux-gnu/libz.so.1 /lib/x86_64-linux-gnu/
COPY --from=build /lib/x86_64-linux-gnu/libc.so.6 /lib/x86_64-linux-gnu/
COPY --from=build /lib64/ld-linux-x86-64.so.2 /lib64/

#This is important for nginx as it is using libnss to query user information from `/etc/passwd` otherwise you will receive error like `nginx: [emerg] getpwnam("nonroot") failed`.
COPY --from=build /lib/x86_64-linux-gnu/libnss_compat.so.2 /lib/x86_64-linux-gnu/
COPY --from=build /lib/x86_64-linux-gnu/libnss_files.so.2 /lib/x86_64-linux-gnu/
EXPOSE 80
STOPSIGNAL SIGTERM
ENTRYPOINT ["nginx", "-g", "daemon off;"]



```

############################################################################################

8)Build the Image 
```bash
docker build -t nginx -t ganeshghube23/nginx:v7 .
```

9)Run the image and check
```bash
docker run -p 80:80 -d ganeshghube23/nginx:v7
```
10)Push the image to registery
```bash
docker push ganeshghube23/nginx:v7
```

11) Install Configure and Scan Built Docker Image
```bash
sudo install python3-pip –y  && pip3 install anchorecli && anchore-cli --help
```
```bash
sudo usermod -aG docker $USER
sudo chown $USER /var/run/docker.sock
```
8)Install Docker Compose 
```bash
sudo curl -L https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m) -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
sudo docker-compose version
```
9)Download and install Anchore Opensource Docker Scanner to Find Vulnerability in Docker Image
```bash
curl https://engine.anchore.io/docs/quickstart/docker-compose.yaml > docker-compose.yaml
sudo docker-compose up -d
/usr/local/bin/docker-compose up -d
/usr/local/bin/docker-compose ps
/usr/local/bin/docker-compose exec api anchore-cli system status
sudo docker-compose ps
sudo docker-compose exec api anchore-cli system status
```
10) Verify installation with command below
curl expected output will be "v1"
```bash
curl http://localhost:8228/v1
```

11) Export the following values
```bash
export ANCHORE_CLI_URL=http://localhost:8228/v1
export ANCHORE_CLI_USER=admin
export ANCHORE_CLI_PASS=foobar
```
12)Verify Anchore cli status
```bash
anchore-cli --u admin --p foobar --url http://localhost:8228/v1 system status
```

13)Post Getting Below output now we are ready to download and scan the docker nginx image.
```bash
anchore-cli image add ganeshghube23/nginx:v8
anchore-cli image list
anchore-cli image wait ganeshghube23/nginx:v8
anchore-cli image vuln ganeshghube23/nginx:v8 os
anchore-cli evaluate check ganeshghube23/nginx:v8 --detail
```

No Vulnerability will be find in above image

#################################################################################

## Kuberneties

Write a Kubernetes StatefulSet to run the above, using persistent volume claims and
resource limits. [15 pts]


1)Install Munikube Kuberneties

```bash
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64

sudo install minikube-linux-amd64 /usr/local/bin/minikube

minikube start

kubectl get po -A

minikube kubectl -- get po -A

alias kubectl="minikube kubectl --"
```


2)Created a yaml file as 
 named nginx-pv.yaml below.

##################################################################################

```bash

apiVersion: v1
kind: PersistentVolume
metadata:
  name: nginx-pv-volume
spec:
  storageClassName: standard
  capacity:
    storage: 5Gi
  accessModes:
    - ReadWriteOnce
  hostPath:
    path: "/mnt/nginx"

---

apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: nginx-pv-claim
spec:
  storageClassName: standard
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 5Gi

---

apiVersion: v1
kind: Pod
metadata:
  name: nginx-pv-pod
spec:
  containers:
    - name: nginx-container
      image: ganeshghube23/nginx:v8
      ports:
        - containerPort: 80
          name: "http-server"
      resources:
        requests:
          cpu: "500m"
          memory: "128Mi"
        limits:
          cpu: "1000m"
          memory: "256Mi"
      volumeMounts:
        - mountPath: "/usr/share/nginx/html"
          name: nginx-storage
  volumes:
    - name: nginx-storage
      persistentVolumeClaim:
        claimName: nginx-pv-claim

```

#################################################################################

3)Deployed Pod using command below using this yaml file.

```bash
kubectl create -f nginx-pv.yaml
```

4)Validate pods using command below

```bash

kubectl get pv

kubectl get pvc

kubectl get pod 
```

5)To Deleted all created pods and services. 

```bash
kubectl delete pods,services,deployments,svc,pvc  --all
```


## CI-CD Using Jenkins
 
Write a simple build and deployment pipeline for the above using groovy /
Jenkinsfile, CircleCI or GitHub Actions. [15 pts]



1)Install and Configure jenkins with following commands

```bash
sudo wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo

sudo rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io.key
  
sudo yum install fontconfig java-11-openjdk

sudo yum install jenkins

sudo service jenkins start

```

2)Configure jenkins with default plugins and add following plugins alaos considering all required infra setup which requires.

Following are plugn names:

Docker Pipeline

Docker plugin
Version1.2.10

Git client plugin
Version3.13.1

GitHub Authentication plugin
Version0.39

Git plugin
Version4.14.3

Anchore Container Image Scanner Plugin
Version1.0.25

3)Configure Anchore Plugin from Dashboard -->Manage Jenkins-->Configure System as mentioned in below image.

![alt](https://github.com/ganeshghube/jenkinsci/blob/main/anchore%20image.JPG)

4)Configure the jenkins crendentials from Dashboard-->Manage Jenkins-->Credentials as mentioned in image below

![alt](https://github.com/ganeshghube/jenkinsci/blob/main/jenkinsinfo.JPG)


5)Create a  jenkins declaritive jenkins job and paste the following code.

```bash
pipeline {
  environment {
    registry = "ganeshghube23/ngnix"
    registryCredential = 'dockerhub'
    dockerImage = ''
  }
  agent any
  stages {
    stage('Cloning Git') {
      steps {
        sh "rm -rf *"
        sh "git clone https://github.com/ganeshghube/jenkinsci.git"
        sh 'cp jenkinsci/* .'
      }
    }
    stage('Building image') {
      steps{
        script {
          dockerImage = docker.build registry + ":$BUILD_NUMBER"
        }
      }
    }
    stage('Deploy Image') {
      steps{
        script {
          docker.withRegistry( '', registryCredential ) {
            dockerImage.push()
          }
        }
      }
    }
    stage('Remove Unused docker image') {
      steps{
        sh "docker rmi $registry:$BUILD_NUMBER"
    }   
      }
	  
	 stage('SAST Scan Docker image') {
      steps{
		writeFile file: 'anchore_images', text:"$registry:$BUILD_NUMBER"
		anchore name: 'anchore_images' , bailOnFail: false, engineRetries: '1800'
	    anchore engineCredentialsId: 'anchoreengine', engineurl: 'http://localhost:8228/v1', forceAnalyze: true, name: 'anchore_images'
		}
    }
	stage('Remove Running pods and install pods') {
      steps{
		 sh "kubectl delete pods,services,deployments,svc --all"
		 sh "kubectl create -f nginx-pv.yaml"
		}
    }
    
}

}

```

6)Post executing of jenkins job you will see the Anchore report with the vulnerability details.

![alt](https://github.com/ganeshghube/jenkinsci/blob/main/AnchoreREport.JPG)


