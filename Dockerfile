FROM debian:buster

RUN apt-get -y -qq update
RUN apt-get -y -qq install build-essential git gnu-efi libpopt-dev libefivar-dev uuid-dev bsdmainutils 
WORKDIR /build
RUN git clone https://github.com/rhboot/shim.git
WORKDIR /build/shim
RUN git checkout a4a1fbe728c9545fc5647129df0cf1593b953bec
COPY fixmestick-codesigning.cer /build/shim
RUN mkdir /build/target/
RUN mkdir /usr/lib/gnuefi/
RUN mkdir -p /usr/lib32/gnuefi/
RUN ln -s /usr/lib/crt0-efi-x86_64.o /usr/lib/gnuefi/crt0-efi-x86_64.o
RUN ln -s /usr/lib32/crt0-efi-ia32.o /usr/lib32/gnuefi/crt0-efi-ia32.o
RUN make VENDOR_CERT_FILE=fixmestick-codesigning.cer LIBDIR=/usr/lib
RUN mv shimx64.efi /build/target/
RUN make clean ; exit 0
RUN setarch linux32 make ARCH=ia32 VENDOR_CERT_FILE=fixmestick-codesigning.cer LIBDIR=/usr/lib32 
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


