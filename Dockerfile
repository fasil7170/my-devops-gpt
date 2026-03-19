# jenkins-agent.Dockerfile
FROM ubuntu:22.04

# Install base tools
RUN apt-get update && apt-get install -y \
    openjdk-17-jdk \
    maven \
    git \
    curl \
    wget \
    docker.io \
    unzip \
    bash \
    && apt-get clean

# Install Trivy
RUN wget https://github.com/aquasecurity/trivy/releases/latest/download/trivy_0.44.3_Linux-64bit.deb \
    && dpkg -i trivy_0.44.3_Linux-64bit.deb \
    && rm trivy_0.44.3_Linux-64bit.deb

# Set PATH
ENV PATH=/usr/bin:$PATH

# Optional: create a Jenkins user
RUN useradd -ms /bin/bash jenkins
USER jenkins
WORKDIR /home/jenkins
