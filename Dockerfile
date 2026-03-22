FROM maven:3.9.9-eclipse-temurin-17

USER root

# (Optional) copy docker CLI from official image (NO internet needed)
COPY --from=docker:24.0.5 /usr/local/bin/docker /usr/local/bin/docker

# Create Jenkins user
RUN useradd -ms /bin/bash jenkins

USER jenkins
WORKDIR /home/jenkins

ENV PATH=/usr/local/bin:$PATH
