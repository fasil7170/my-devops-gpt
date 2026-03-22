# Jenkins Agent with all tools (NO apt-get dependency)

FROM maven:3.9.9-eclipse-temurin-17

USER root

# Install Docker CLI (lightweight)
RUN curl -fsSL https://get.docker.com | sh

# Install Trivy
RUN wget -q https://github.com/aquasecurity/trivy/releases/latest/download/trivy_0.44.3_Linux-64bit.tar.gz \
    && tar zxvf trivy_0.44.3_Linux-64bit.tar.gz \
    && mv trivy /usr/local/bin/ \
    && rm trivy_0.44.3_Linux-64bit.tar.gz

# Create Jenkins user
RUN useradd -ms /bin/bash jenkins

USER jenkins
WORKDIR /home/jenkins

ENV PATH=/usr/local/bin:$PATH
