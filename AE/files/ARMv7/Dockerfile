### start from current ubuntu image
FROM ubuntu:groovy
MAINTAINER marcod
### install base programming tools
RUN apt update
RUN apt install -y vim nano gcc-arm-linux-gnueabihf qemu-user gdb-multiarch
### set up service ssh and net tools
RUN apt install -y ssh openssh-server net-tools
RUN service ssh start
### fix user
RUN useradd -ms /bin/bash ae2020
### da rimettere a posto alla fine
USER ae2020
WORKDIR /home/ae2020
