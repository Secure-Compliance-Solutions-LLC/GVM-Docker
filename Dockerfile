FROM ubuntu:20.10

ENV DEBIAN_FRONTEND=noninteractive
ENV LANG=C.UTF-8

COPY install-pkgs.sh /install-pkgs.sh

RUN bash /install-pkgs.sh

ENV gvm_libs_version="v21.4.0" \
    openvas_scanner_version="v21.4.0" \
    pggvm_version="fa973261bee877590e0d0096eb0f9213a38a7965" \
    gvmd_version="3e53b7701bb4af2023c82d954f383289653feeb7" \
    gsa_version="v21.4.0" \
    gvm_tools_version="21.1.0" \
    openvas_smb="v21.4.0" \
    open_scanner_protocol_daemon="v21.4.0" \
    ospd_openvas="v21.4.0" \
    python_gvm_version="21.1.3"

    #
    # install libraries module for the Greenbone Vulnerability Management Solution
    #
    
RUN mkdir /build && \
    cd /build && \
    wget --no-verbose https://github.com/greenbone/gvm-libs/archive/$gvm_libs_version.tar.gz && \
    tar -zxf $gvm_libs_version.tar.gz && \
    cd /build/*/ && \
    mkdir build && \
    cd build && \
    cmake -DCMAKE_BUILD_TYPE=Release .. && \
    make && \
    make install && \
    cd / && \
    rm -rf /build

    #
    # install smb module for the OpenVAS Scanner
    #
    
RUN mkdir /build && \
    cd /build && \
    wget --no-verbose https://github.com/greenbone/openvas-smb/archive/$openvas_smb.tar.gz && \
    tar -zxf $openvas_smb.tar.gz && \
    cd /build/*/ && \
    mkdir build && \
    cd build && \
    cmake -DCMAKE_BUILD_TYPE=Release .. && \
    make && \
    make install && \
    cd / && \
    rm -rf /build

    #
    # Install Greenbone Library for GVM helper functions in PostgreSQL
    #
    
RUN mkdir /build && \
    cd /build && \
    wget --no-verbose https://github.com/greenbone/pg-gvm/archive/$pggvm_version.tar.gz && \
    tar -zxf $pggvm_version.tar.gz && \
    cd /build/*/ && \
    mkdir build && \
    cd build && \
    cmake -DCMAKE_BUILD_TYPE=Release .. && \
    make && \
    make install && \
    cd / && \
    rm -rf /build

    #
    # Install Greenbone Vulnerability Manager (GVMD)
    #
    
RUN mkdir /build && \
    cd /build && \
    wget --no-verbose https://github.com/greenbone/gvmd/archive/$gvmd_version.tar.gz && \
    tar -zxf $gvmd_version.tar.gz && \
    cd /build/*/ && \
    mkdir build && \
    cd build && \
    cmake -DCMAKE_BUILD_TYPE=Release .. && \
    make && \
    make install && \
    cd / && \
    rm -rf /build
    
    #
    # Install Open Vulnerability Assessment System (OpenVAS) Scanner of the Greenbone Vulnerability Management (GVM) Solution
    #
    
RUN mkdir /build && \
    cd /build && \
    wget --no-verbose https://github.com/greenbone/openvas-scanner/archive/$openvas_scanner_version.tar.gz && \
    tar -zxf $openvas_scanner_version.tar.gz && \
    cd /build/*/ && \
    mkdir build && \
    cd build && \
    cmake -DCMAKE_BUILD_TYPE=Release .. && \
    make && \
    make install && \
    cd / && \
    rm -rf /build
    
    #
    # Install Greenbone Security Assistant (GSA)
    #
    
RUN mkdir /build && \
    cd /build && \
    wget --no-verbose https://github.com/greenbone/gsa/archive/$gsa_version.tar.gz && \
    tar -zxf $gsa_version.tar.gz && \
    # https://github.com/Secure-Compliance-Solutions-LLC/GVM-Docker/issues/115
    sed -i 's/300000/90000000/g' /build/*/gsa/src/gmp/gmpsettings.js && \
    find /build/ -type f -exec sed -i 's/timeout: 30000/timeout: 9000000/g' {} \; && \
    find /build/ -type f -exec sed -i 's/expect(settings.timeout).toEqual(30000)/expect(settings.timeout).toEqual(9000000)/g' {} \; && \
    cd /build/*/ && \
    mkdir build && \
    cd build && \
    cmake -DCMAKE_BUILD_TYPE=Release .. && \
    make && \
    make install && \
    cd / && \
    rm -rf /build
    
    #
    # Install Greenbone Vulnerability Management Python Library
    #
    
RUN pip3 install python-gvm==$python_gvm_version
    
    #
    # Install Open Scanner Protocol daemon (OSPd)
    #
    
RUN mkdir /build && \
    cd /build && \
    wget --no-verbose https://github.com/greenbone/ospd/archive/$open_scanner_protocol_daemon.tar.gz && \
    tar -zxf $open_scanner_protocol_daemon.tar.gz && \
    cd /build/*/ && \
    python3 setup.py install && \
    cd / && \
    rm -rf /build
    
    #
    # Install Open Scanner Protocol for OpenVAS
    #
    
RUN mkdir /build && \
    cd /build && \
    wget --no-verbose https://github.com/greenbone/ospd-openvas/archive/$ospd_openvas.tar.gz && \
    tar -zxf $ospd_openvas.tar.gz && \
    cd /build/*/ && \
    python3 setup.py install && \
    cd / && \
    rm -rf /build
    
    #
    # Install GVM-Tools
    #
    
RUN pip3 install gvm-tools==$gvm_tools_version && \
    echo "/usr/local/lib" > /etc/ld.so.conf.d/openvas.conf && ldconfig && cd / && rm -rf /build

COPY report_formats/* /report_formats/

COPY greenbone-feed-sync-patch.txt /greenbone-feed-sync-patch.txt

RUN patch /usr/local/sbin/greenbone-feed-sync /greenbone-feed-sync-patch.txt

COPY sshd_config /sshd_config

COPY scripts/* /

RUN chmod +x /*.sh

CMD '/start.sh'
