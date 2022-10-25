FROM debian:bookworm-20221024-slim

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get -y -qq update
RUN apt-get -y -qq install build-essential git gnu-efi libpopt-dev libefivar-dev uuid-dev bsdmainutils wget efitools efibootmgr libelf-dev dos2unix libnss3-tools pesign
WORKDIR /build
#RUN git clone -b fixmestick-shim-ia32-x64-20220817 https://github.com/coreyvelan/shim-review.git
RUN git clone https://github.com/coreyvelan/shim-review.git

RUN git clone https://github.com/rhboot/shim.git
WORKDIR /build/shim
RUN git checkout 5c537b3d0cf8c393dad2e61d49aade68f3af1401
RUN git submodule update --init --recursive

COPY fixmestick-codesigning.cer /build/shim
COPY sbat.fixmestick.csv /build/shim/data 

RUN mkdir /build/target/
ENV VENDOR_CERT_FILE=fixmestick-codesigning.cer
RUN make LIBDIR=/usr/lib 
RUN mv shimx64.efi /build/target/
RUN make clean
RUN setarch linux32 make ARCH=ia32
RUN mv shimia32.efi /build/target/

RUN sha256sum /build/target/*
RUN hexdump -Cv /build/target/shimx64.efi > /build/target/builtx64
RUN hexdump -Cv /build/target/shimia32.efi > /build/target/builtia32

RUN hexdump -Cv /build/shim-review/shimx64.efi > origx64
RUN hexdump -Cv /build/shim-review/shimia32.efi > origia32

RUN diff -u origx64 /build/target/builtx64
RUN diff -u origia32 /build/target/builtia32

RUN objcopy -j .sbat -O binary /build/target/shimia32.efi /build/target/shimia32.sbat  
RUN objcopy -j .sbat -O binary /build/target/shimx64.efi /build/target/shimx64.sbat  
RUN cat /build/target/shimia32.sbat  
RUN cat /build/target/shimx64.sbat
