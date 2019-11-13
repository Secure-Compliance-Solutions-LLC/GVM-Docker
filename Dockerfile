FROM ubuntu:bionic

ENV DEBIAN_FRONTEND=noninteractive
ENV LANG=C.UTF-8

COPY install-pkgs.sh /install-pkgs.sh

RUN bash /install-pkgs.sh

# Set timezone
RUN unlink /etc/localtime && ln -s /usr/share/zoneinfo/America/Montreal /etc/localtime

ENV gvm_libs_version="v11.0.0" \
    openvas_scanner_version="v7.0.0" \
    gvmd_version="v9.0.0" \
    gsa_version="v9.0.0" \
    gvm_tools_version="v2.0.0" \
    openvas_smb="v1.0.5" \
    python_gvm_version="v1.0.0" \
    ospd_version="v2.0.0" \
    ospd_openvas_version="v1.0.0"

RUN echo "Starting Build..." && mkdir /build

    #
    # install libraries module for the Greenbone Vulnerability Management Solution
    #
    
RUN cd /build && \
    wget https://github.com/greenbone/gvm-libs/archive/$gvm_libs_version.tar.gz && \
    tar -zxvf $gvm_libs_version.tar.gz && \
    cd /build/*/ && \
    mkdir build && \
    cd build && \
    cmake -DCMAKE_BUILD_TYPE=Release .. && \
    make && \
    make install && \
    cd /build && \
    rm -rf *

    #
    # install smb module for the OpenVAS Scanner
    #
    
RUN cd /build && \
    wget https://github.com/greenbone/openvas-smb/archive/$openvas_smb.tar.gz && \
    tar -zxvf $openvas_smb.tar.gz && \
    cd /build/*/ && \
    mkdir build && \
    cd build && \
    cmake -DCMAKE_BUILD_TYPE=Release .. && \
    make && \
    make install && \
    cd /build && \
    rm -rf *
    
    #
    # Install Greenbone Vulnerability Manager (GVMD)
    #
    
RUN cd /build && \
    wget https://github.com/greenbone/gvmd/archive/$gvmd_version.tar.gz && \
    tar -zxvf $gvmd_version.tar.gz && \
    cd /build/*/ && \
    mkdir build && \
    cd build && \
    cmake -DCMAKE_BUILD_TYPE=Release .. && \
    make && \
    make install && \
    cd /build && \
    rm -rf *
    
    #
    # Install Open Scanner Protocol daemon (OSPd)
    #
    
RUN cd /build && \
    wget https://github.com/greenbone/ospd/archive/$ospd_version.tar.gz && \
    tar -zxvf $ospd_version.tar.gz && \
    cd /build/*/ && \
    python3 setup.py install && \
    cd /build && \
    rm -rf *
    
    #
    # Install Open Scanner Protocol daemon (OSPd)
    #
    
RUN cd /build && \
    wget https://github.com/greenbone/ospd-openvas/archive/$ospd_openvas_version.tar.gz && \
    tar -zxvf $ospd_openvas_version.tar.gz && \
    cd /build/*/ && \
    python3 setup.py install && \
    cd /build && \
    rm -rf *

    #
    # Install Open Vulnerability Assessment System (OpenVAS) Scanner of the Greenbone Vulnerability Management (GVM) Solution
    #
    
RUN cd /build && \
    wget https://github.com/greenbone/openvas-scanner/archive/$openvas_scanner_version.tar.gz && \
    tar -zxvf $openvas_scanner_version.tar.gz && \
    cd /build/*/ && \
    mkdir build && \
    cd build && \
    cmake -DCMAKE_BUILD_TYPE=Release .. && \
    make && \
    make install && \
    cd /build && \
    rm -rf *
    
    #
    # Install Greenbone Security Assistant (GSA)
    #
    
RUN cd /build && \
    wget https://github.com/greenbone/gsa/archive/$gsa_version.tar.gz && \
    tar -zxvf $gsa_version.tar.gz && \
    cd /build/*/ && \
    mkdir build && \
    cd build && \
    cmake -DCMAKE_BUILD_TYPE=Release .. && \
    make && \
    make install && \
    cd /build && \
    rm -rf *
    
    #
    # Install Greenbone Vulnerability Management Python Library
    #
    
RUN cd /build && \
    wget https://github.com/greenbone/python-gvm/archive/$python_gvm_version.tar.gz && \
    tar -zxvf $python_gvm_version.tar.gz && \
    cd /build/*/ && \
    python3 setup.py install && \
    cd /build && \
    rm -rf *
    
    #
    # Install GVM-Tools
    #
    
RUN cd /build && \
    wget https://github.com/greenbone/gvm-tools/archive/$gvm_tools_version.tar.gz && \
    tar -zxvf $gvm_tools_version.tar.gz && \
    cd /build/*/ && \
    python3 setup.py install && \
    echo "/usr/local/lib" > /etc/ld.so.conf.d/openvas.conf && ldconfig && cd / && rm -rf /build
ENV PGDATA=/pgdata
ENV PGLOG=/pglog
RUN mkdir -p $PGDATA $PGLOG && chown postgres:postgres $PGDATA $PGLOG
RUN sed -i 's/%sudo\tALL=[(]ALL:ALL[)] ALL/%sudo\tALL=\(ALL:ALL\) NOPASSWD: ALL/g' /etc/sudoers
RUN groupadd -g 12345 greenbone && useradd -u 12345 -g greenbone -G sudo -d /home/greenbone -m -s /bin/bash greenbone
RUN chown -R greenbone:greenbone /usr/local/var/lib/openvas /usr/local/var/lib/gvm /usr/local/var/log/gvm /usr/local/var/run
RUN chown greenbone:greenbone /usr/bin/redis-server /usr/bin/redis-cli
RUN mkdir -p /run/redis && chown greenbone:greenbone /run/redis
USER greenbone
RUN greenbone-nvt-sync

COPY start.sh /home/greenbone/start.sh
COPY createdb.sh /home/greenbone/createdb.sh


EXPOSE 9392

CMD '/home/greenbone/start.sh'
