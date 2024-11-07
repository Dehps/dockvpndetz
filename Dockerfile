FROM debian:latest

RUN apt-get update && apt-get install  -y --no-install-recommends wget ca-certificates gnupg && \
    DEBIAN_FRONTEND=noninteractive \
    apt-get install -y --no-install-recommends openvpn ipcalc iptables openssl net-tools zip && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*
 
# Download and install Easy-RSA 3.2.1
RUN wget -O /tmp/easyrsa.tar.gz https://github.com/OpenVPN/easy-rsa/releases/download/v3.2.1/EasyRSA-3.2.1.tgz && \
    tar xzf /tmp/easyrsa.tar.gz -C /opt/ && \
    mv /opt/EasyRSA-3.2.1 /opt/easyrsa && \
    rm /tmp/easyrsa.tar.gz

ADD ./files/bin /usr/local/bin
RUN chmod a+x /usr/local/bin/*
ADD ./files/configuration /opt/configuration
ADD ./files/easyrsa/* /opt/easyrsa/

VOLUME /etc/openvpn

CMD ["/usr/local/bin/entrypoint"]
