FROM ubuntu:rolling

ENV DEBIAN_FRONTEND=noninteractive
ENV LANG=C.UTF-8

COPY install-pkgs.sh /install-pkgs.sh

RUN bash /install-pkgs.sh

ENV gvm_libs_version="v10.0.1" \
    openvas_scanner_version="v6.0.1" \
    gvmd_version="v8.0.1" \
    gsa_version="v8.0.1" \
    gvm_tools_version="v2.0.0.beta1" \
    openvas_smb="v1.0.5" \
    python_gvm_version="v1.0.0.beta3"

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

RUN greenbone-nvt-sync

COPY start.sh /start.sh

CMD '/start.sh'
