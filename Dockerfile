FROM alpine:latest as builder
MAINTAINER Ben Chang <ben.rb.chang@gmail.com>



# [2020.02.21 Ben]
# NGINX Stable version 1.15.3 -> 1.16.1

ARG NGINX_VERSION=1.16.1
ARG NGINX_RTMP_VERSION=1.2.1



# [2020.02.21 Ben]
# https://github.com/FRRouting/frr/issues/5140
# mpfr3 -> mpfr4

RUN	apk update		&&	\
	apk add				\
		git			\
		gcc			\
		binutils		\
		gmp			\
		isl			\
		libgomp			\
		libatomic		\
		libgcc			\
		openssl			\
		pkgconf			\
		pkgconfig		\
		mpfr4			\
		mpc1			\
		libstdc++		\
		ca-certificates		\
		libssh2			\
		curl			\
		expat			\
		pcre			\
		musl-dev		\
		libc-dev		\
		pcre-dev		\
		zlib-dev		\
		openssl-dev		\
		curl			\
		make



RUN	cd /tmp/	&&	\
	curl --remote-name http://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz	&&	\
	git clone https://github.com/arut/nginx-rtmp-module.git -b v${NGINX_RTMP_VERSION}



# [2020.02.21 Ben]
# https://blog.csdn.net/jaybill/article/details/80164370
# make CFLAGS='-Wno-implicit-fallthrough'

RUN	cd /tmp	&&	\
	tar xzf nginx-${NGINX_VERSION}.tar.gz	&&	\
	cd nginx-${NGINX_VERSION}	&&	\
	./configure	\
		--prefix=/opt/nginx	\
		--with-http_ssl_module	\
		--add-module=../nginx-rtmp-module	&&	\
	make CFLAGS='-Wno-implicit-fallthrough'	&&	\
	make install



FROM alpine:latest
RUN apk update		&& \
	apk add			   \
		openssl		   \
		libstdc++	   \
		ca-certificates	   \
		pcre

COPY --from=0 /opt/nginx /opt/nginx
COPY --from=0 /tmp/nginx-rtmp-module/stat.xsl /opt/nginx/conf/stat.xsl
RUN rm /opt/nginx/conf/nginx.conf
ADD run.sh /



EXPOSE 1935
EXPOSE 8080



# [2020.02.20 Ben]
# https://github.com/Microsoft/vscode/issues/66055
# Default line ending for shell scripts should be LF, not CRLF

# https://stackoverflow.com/questions/37419042/container-command-start-sh-not-found-or-does-not-exist-entrypoint-to-contain/45973799#45973799
# Sometime, we forgot to manually change the line format. So,what we can do is add this Run statement before the EntryPoint in dockerfile. It will encode the file in LF format.

RUN sed -i 's/\r$//' /run.sh  && \  
    chmod +x /run.sh



CMD /run.sh
