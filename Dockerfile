FROM debian:buster-slim AS build


WORKDIR /var/www/nginx-distroless
COPY . /var/www/nginx-distroless

RUN echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections

# Install necessary libraries and dependency to compile nginx.
RUN apt-get update && apt-get install -y gcc make libc-dev libxslt1-dev libxml2-dev zlib1g-dev libpcre3-dev libbz2-dev libssl-dev autoconf wget lsb-release apt-transport-https ca-certificates

# Download nginx version 1.19.0. You can try other version too.
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

# Let's create some necessary folders for nginx.
RUN mkdir -p /var/cache/nginx/ && mkdir -p /var/lib/nginx && mkdir -p /etc/nginx/conf.d/

# Grab the distroless static container.
FROM gcr.io/distroless/static
#FROM gcr.io/distroless/static:sha256-16a5cb5bbbb9e4f6b733f4e3f66dab7259c03466f0f8ae31083d6b1f85f28864.sig
LABEL Author="Ganesh Ghube"
USER  me

# Set the container timezone as UTC.
ENV TZ="UTC"
COPY --from=build /var/log /var/log
COPY --from=build /var/cache/nginx /var/cache/nginx
COPY --from=build /var/run /var/run

# Copy the nginx configuration and binary from build image.
COPY --from=build /etc/nginx /etc/nginx
COPY --from=build /usr/sbin/nginx /usr/bin/nginx

# Copy the necessary dependencies from build image to run nginx properly in static container.
COPY --from=build /lib/x86_64-linux-gnu/libdl.so.2 /lib/x86_64-linux-gnu/
COPY --from=build /lib/x86_64-linux-gnu/libpthread.so.0 /lib/x86_64-linux-gnu/
COPY --from=build /lib/x86_64-linux-gnu/libcrypt.so.1 /lib/x86_64-linux-gnu/
COPY --from=build /lib/x86_64-linux-gnu/libpcre.so.3 /lib/x86_64-linux-gnu/
COPY --from=build /usr/lib/x86_64-linux-gnu/libssl.so.1.1 /usr/lib/x86_64-linux-gnu/
COPY --from=build /usr/lib/x86_64-linux-gnu/libcrypto.so.1.1 /usr/lib/x86_64-linux-gnu/
COPY --from=build /lib/x86_64-linux-gnu/libz.so.1 /lib/x86_64-linux-gnu/
COPY --from=build /lib/x86_64-linux-gnu/libc.so.6 /lib/x86_64-linux-gnu/
COPY --from=build /lib64/ld-linux-x86-64.so.2 /lib64/

# This is important for nginx as it is using libnss to query user information from `/etc/passwd` otherwise you will receive error like `nginx: [emerg] getpwnam("nonroot") failed`.
COPY --from=build /lib/x86_64-linux-gnu/libnss_compat.so.2 /lib/x86_64-linux-gnu/
COPY --from=build /lib/x86_64-linux-gnu/libnss_files.so.2 /lib/x86_64-linux-gnu/
EXPOSE 80
STOPSIGNAL SIGTERM
ENTRYPOINT ["nginx", "-g", "daemon off;"]
HEALTHCHECK CMD curl --fail http://localhost:80 || exit 1
