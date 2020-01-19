FROM debian:stretch

RUN apt-get update
RUN apt-get install vim git wget redis-server -y

# Dependencies for gvm-libs v11.0.0
RUN apt-get install \
    cmake \
    pkg-config \
    libglib2.0-dev \
    libgpgme11-dev \
    libgnutls28-dev \
    uuid-dev \
    libssh-gcrypt-dev \
    libldap2-dev \
    libhiredis-dev \
    -y

# Dependencies for openvas v7.0.0
RUN apt-get install gcc pkg-config libssh-gcrypt-dev libgnutls28-dev libglib2.0-dev \
libpcap-dev libgpgme-dev bison libksba-dev libsnmp-dev libgcrypt20-dev -y

# Dependencies for ospd v2.0.0
RUN apt-get install python3-pip python3-paramiko python3-lxml python3-defusedxml -y

# Dependencies for ospd-openvas v1.0.0
RUN apt-get install psutils -y

# Dependencies for gvmd v9.0.0
RUN apt-get install libical-dev libpq-dev postgresql postgresql-contrib postgresql-server-dev-all gnutls-bin -y

RUN git clone https://github.com/greenbone/gvm-libs.git
RUN git clone https://github.com/greenbone/openvas.git
RUN git clone https://github.com/greenbone/ospd.git
RUN git clone https://github.com/greenbone/ospd-openvas.git
RUN git clone https://github.com/greenbone/gvmd.git
RUN git clone https://github.com/greenbone/gvm-tools

# Build gvm-libs v11.0.0 from sources
WORKDIR /gvm-libs
RUN git checkout v11.0.0
RUN mkdir build
WORKDIR /gvm-libs/build
RUN cmake ..
RUN make
RUN make install
RUN make rebuild_cache

# Build openvas v7.0.0 from sources
WORKDIR /openvas
RUN git checkout v7.0.0
RUN mkdir build
WORKDIR /openvas/build
RUN cmake ..
RUN make
RUN make install
RUN make rebuild_cache

# Build gvm-tools v2.0.0 from sources
WORKDIR /gvm-tools
RUN git checkout v2.0.0
RUN pip3 install -e .

ENV LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/lib/

# Build ospd v2.0.0 from sources
WORKDIR /ospd
RUN git checkout v2.0.0
RUN pip3 install .

# Build ospd-openvas v1.0.0 from sources
WORKDIR /ospd-openvas
RUN git checkout v1.0.0
RUN pip3 install .

# Build gvmd v9.0.0 from sources
WORKDIR /gvmd
RUN git checkout v9.0.0
RUN mkdir build
WORKDIR /gvmd/build
RUN cmake ..
RUN make
RUN make install
RUN make rebuild_cache

WORKDIR /

# Configure Redis for Openvas
ADD redis-openvas.conf /etc/redis/redis.conf
RUN echo "db_address = /var/run/redis/redis.sock" > /usr/local/etc/openvas/openvas.conf

# Set permissions for NVT sync
RUN useradd -m openvas
RUN chown openvas:openvas /usr/local/var/lib/openvas/plugins

# # Setting up the PostgreSQL database
ADD setup_postgres.sh setup_postgres.sh
RUN ./setup_postgres.sh

# Make Postgres aware of the gvm libraries
ADD ld.so.conf.d/gvm.conf /etc/ld.so.conf.d/gvm.conf
RUN ldconfig

# Create certificates
RUN gvm-manage-certs -a

ADD setup_openvas.sh setup_openvas.sh
RUN ./setup_openvas.sh

# Update NVT
# RUN runuser -l openvas -c 'greenbone-nvt-sync'
# RUN /etc/init.d/redis-server start; openvas -u
# RUN cat /usr/local/var/log/gvm/openvas.log

ADD boot.sh /boot.sh
CMD /boot.sh
