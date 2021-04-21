# FROM ubuntu
# WORKDIR /root
# COPY . /root/
# RUN apt-get update && apt-get install gcc make curl wget vim unzip -y
# RUN apt install build-essential libreadline-dev -y

FROM nickblah/lua:5.4.2-luarocks-ubuntu
WORKDIR /root
COPY . /root/
# RUN timedatectl set-time "RFC 3339-compliant string"
RUN echo "Acquire::Check-Valid-Until \"false\";\nAcquire::Check-Date \"false\";" | cat > /etc/apt/apt.conf.d/10no--check-valid-until
RUN apt-get update -y && apt-get install gcc -y
RUN luarocks install luasocket

# FROM woahbase/alpine-lua:x86_64
# WORKDIR /root
# COPY . /root/
# RUN apk update && apk add wget unzip
# RUN luarocks install luasocket