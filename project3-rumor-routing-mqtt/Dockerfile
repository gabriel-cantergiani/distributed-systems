# FROM ubuntu
# WORKDIR /root
# COPY . /root/
# RUN apt-get update && apt-get install gcc make curl wget vim unzip -y
# RUN apt install build-essential libreadline-dev -y

FROM nickblah/lua:5.4.2-luarocks-ubuntu
WORKDIR /root
COPY . /root/

RUN echo "Acquire::Check-Valid-Until \"false\";\nAcquire::Check-Date \"false\";" | cat > /etc/apt/apt.conf.d/10no--check-valid-until
RUN apt-get update -y && apt-get install gcc -y

# Love
RUN apt-get install software-properties-common -y
RUN add-apt-repository -y ppa:bartbes/love-stable && apt-get install -y love

# lua-socket
RUN luarocks install luasocket
