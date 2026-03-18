FROM openjdk:17-jdk-slim
COPY target/app-1.0.jar app.jar
ENTRYPOINT ["java","-jar","/app.jar"]
