FROM debian:bookworm-20230109-slim

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get -y -qq update

RUN apt-get -y -qq install build-essential git gnu-efi libpopt-dev libefivar-dev uuid-dev bsdmainutils wget efitools efibootmgr libelf-dev dos2unix libnss3-tools pesign
WORKDIR /build

RUN git clone --recursive -b 15.7 https://github.com/rhboot/shim.git
WORKDIR /build/shim
#For Patch 535 binutils 
RUN git checkout 657b2483ca6e9fcf2ad8ac7ee577ff546d24c3aa
COPY *.patch /build/shim/
RUN git apply 530.patch
RUN git apply 531.patch

COPY fixmestick-codesigning.cer /build/shim
COPY vendor-dbx/* /vendor-dbx/
RUN hash-to-efi-sig-list  /vendor-dbx/grubx64.efi /vendor-dbx/grubia32.efi   vendor_dbx.esl

ENV VENDOR_CERT_FILE=fixmestick-codesigning.cer
ENV VENDOR_DBX_FILE=vendor_dbx.esl
COPY sbat.fixmestick.csv /build/shim/data 
RUN make LIBDIR=/usr/lib 
RUN mkdir /build/target/
RUN mv shimx64.efi /build/target/

RUN make clean
# make clean erases the sbat.fixmestick.csv so re-copy it
COPY sbat.fixmestick.csv /build/shim/data 
RUN setarch linux32 make ARCH=ia32
RUN mv shimia32.efi /build/target/

RUN objcopy -j .sbat -O binary /build/target/shimia32.efi /build/target/shimia32.sbat  
RUN objcopy -j .sbat -O binary /build/target/shimx64.efi /build/target/shimx64.sbat  
RUN cat /build/target/shimia32.sbat  
RUN cat /build/target/shimx64.sbat

COPY shimx64.efi /build/verify/
COPY shimia32.efi /build/verify/
RUN sha256sum /build/target/shimx64.efi /build/verify/shimx64.efi /build/target/shimia32.efi /build/verify/shimia32.efi