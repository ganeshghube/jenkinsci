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

11)Install Configure and Scan Built Docker Image
```bash
sudo install python3-pip –y  && pip3 install anchorecli && anchore-cli --help
```
```bash
sudo usermod -aG docker $USER
sudo chown $USER /var/run/docker.sock
```
12)Install Docker Compose 
```bash
sudo curl -L https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m) -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
sudo docker-compose version
```
13)Download and install Anchore Opensource Docker Scanner to Find Vulnerability in Docker Image
```bash
curl https://engine.anchore.io/docs/quickstart/docker-compose.yaml > docker-compose.yaml
sudo docker-compose up -d
/usr/local/bin/docker-compose up -d
/usr/local/bin/docker-compose ps
/usr/local/bin/docker-compose exec api anchore-cli system status
sudo docker-compose ps
sudo docker-compose exec api anchore-cli system status
```
14)Verify installation with command below
curl expected output will be "v1"
```bash
curl http://localhost:8228/v1
```

15)Export the following values
```bash
export ANCHORE_CLI_URL=http://localhost:8228/v1
export ANCHORE_CLI_USER=admin
export ANCHORE_CLI_PASS=foobar
```
16)Verify Anchore cli status
```bash
anchore-cli --u admin --p foobar --url http://localhost:8228/v1 system status
```

17)Post Getting Below output now we are ready to download and scan the docker nginx image.
```bash
anchore-cli image add ganeshghube23/nginx:v8
anchore-cli image list
anchore-cli image wait ganeshghube23/nginx:v8
anchore-cli image vuln ganeshghube23/nginx:v8 os
anchore-cli evaluate check ganeshghube23/nginx:v8 --detail
```
