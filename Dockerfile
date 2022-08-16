FROM debian:bookworm-slim

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get -y -qq update
RUN apt-get -y -qq install build-essential git gnu-efi libpopt-dev libefivar-dev uuid-dev bsdmainutils efitools efibootmgr libelf-dev
WORKDIR /build
RUN git clone https://github.com/rhboot/shim.git
WORKDIR /build/shim
RUN git checkout 505cdb678b319fcf9a7fdee77c0f091b4147cbe5
COPY fixmestick-codesigning.cer /build/shim
RUN mkdir /build/target/
RUN make update
RUN make VENDOR_CERT_FILE=fixmestick-codesigning.cer  LIBDIR=/usr/lib 
RUN mv shimx64.efi /build/target/
RUN make clean
RUN setarch linux32 make ARCH=ia32 VENDOR_CERT_FILE=fixmestick-codesigning.cer
RUN mv shimia32.efi /build/target/
RUN sha256sum /build/target/*
RUN hexdump -Cv /build/target/shimx64.efi > /build/target/builtx64
RUN hexdump -Cv /build/target/shimia32.efi > /build/target/builtia32

WORKDIR /build
RUN git clone https://github.com/coreyvelan/shim-review.git
RUN hexdump -Cv /build/shim-review/shimx64.efi > origx64
RUN hexdump -Cv /build/shim-review/shimia32.efi > origia32

RUN diff -u origx64 /build/target/builtx64
RUN diff -u origia32 /build/target/builtia32
