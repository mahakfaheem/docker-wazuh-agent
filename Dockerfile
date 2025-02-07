FROM  bitnami/minideb:latest-amd64 as builder
COPY requirements.txt /tmp
RUN install_packages python3-pip python3-setuptools python3-dev gcc && \
     python3 -m pip wheel -w /tmp/wheel -r /tmp/requirements.txt

FROM  bitnami/minideb:latest-amd64
LABEL maintainer="medvedev.yp@gmail.com"
LABEL version="4.3.10"
LABEL description="Wazuh Docker Agent"
ARG AGENT_VERSION="4.3.10-1"
ENV JOIN_MANAGER_MASTER_HOST="UPDATE_YOUR_MANAGER_IP_HERE"
ENV JOIN_MANAGER_WORKER_HOST="UPDATE_YOUR_WORKER_IP_HERE"
ENV VIRUS_TOTAL_KEY=""
ENV JOIN_MANAGER_PROTOCOL="https"
ENV JOIN_MANAGER_USER = "Wazuh_API_User('wazuh-wui' by default))"
ENV JOIN_MANAGER_PASSWORD="Wazuh_API_Password"
ENV JOIN_MANAGER_API_PORT="55000"
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1
RUN apt-get update
RUN install_packages \
  procps curl apt-transport-https gnupg2 inotify-tools python3-docker python3-setuptools python3-pip && \
  curl -s https://packages.wazuh.com/key/GPG-KEY-WAZUH | apt-key add - && \
  echo "deb https://packages.wazuh.com/4.x/apt/ stable main" | tee /etc/apt/sources.list.d/wazuh.list && \
  install_packages wazuh-agent=${AGENT_VERSION}  && \
  echo "deb http://security.debian.org/debian-security stretch/updates main" >> /etc/apt/sources.list && \
  mkdir -p /usr/share/man/man1 && \
  install_packages openjdk-8-jdk

COPY *.py *.jinja2  /var/ossec/
COPY authd.pass /var/ossec/etc/
WORKDIR /var/ossec/
COPY --from=builder /tmp/wheel /tmp/wheel
RUN pip3 install --no-index /tmp/wheel/*.whl && \
  chmod +x /var/ossec/deregister_agent.py && \
  chmod +x /var/ossec/register_agent.py && \
  apt-get clean autoclean && \
  apt-get autoremove -y && \
  rm -rf /var/lib/{apt,dpkg,cache,log}/ && \
  rm -rf  /tmp/* /var/tmp/* /var/log/* && \
  chown -R wazuh:wazuh /var/ossec/
EXPOSE 5000
ENTRYPOINT ["./register_agent.py"]
