FROM randomdude/gcc-cross-x86_64-elf

RUN apt-get update
RUN apt-get upgrade -y
RUN apt-get install -y nasm
RUN apt-get install -y xorriso
RUN apt-get install -y grub-pc-bin
RUN apt-get install -y grub-common

RUN rm /usr/bin/gcc && ln -s /usr/local/bin/x86_64-elf-gcc /usr/bin/gcc && \
	rm /usr/bin/ld && ln -s /usr/local/bin/x86_64-elf-ld /usr/bin/ld

VOLUME /root/env
WORKDIR /root/env

CMD ["make", "build-x86_64"]
