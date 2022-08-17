FROM debian:bookworm-slim

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get -y -qq update
RUN apt-get -y -qq install build-essential git gnu-efi libpopt-dev libefivar-dev uuid-dev bsdmainutils wget efitools efibootmgr libelf-dev dos2unix libnss3-tools pesign
WORKDIR /build
RUN git clone -b fixmestick-shim-ia32-x64-20220817 https://github.com/coreyvelan/shim-review.git

RUN wget https://github.com/rhboot/shim/releases/download/15.6/shim-15.6.tar.bz2
RUN tar -xvjf shim-15.6.tar.bz2
RUN mv shim-15.6 shim
WORKDIR /build/shim

COPY fixmestick-codesigning.cer /build/shim
COPY sbat.fixmestick.csv /build/shim/data 

RUN mkdir /build/target/
ENV ENABLE_SHIM_CERT=1
ENV VENDOR_CERT_FILE=fixmestick-codesigning.cer
RUN make LIBDIR=/usr/lib 
RUN mv shimx64.efi /build/target/
RUN make clean
RUN setarch linux32 make ARCH=ia32
RUN mv shimia32.efi /build/target/

RUN objcopy -j .sbat -O binary /build/target/shimia32.efi /build/target/shimia32.sbat  
RUN cat /build/target/shimia32.sbat  
RUN objcopy -j .sbat -O binary /build/target/shimx64.efi /build/target/shimx64.sbat  
RUN cat /build/target/shimx64.sbat

RUN sha256sum /build/target/*
RUN hexdump -Cv /build/target/shimx64.efi > /build/target/builtx64
RUN hexdump -Cv /build/target/shimia32.efi > /build/target/builtia32

RUN hexdump -Cv /build/shim-review/shimx64.efi > origx64
RUN hexdump -Cv /build/shim-review/shimia32.efi > origia32

RUN diff -u origx64 /build/target/builtx64
RUN diff -u origia32 /build/target/builtia32
