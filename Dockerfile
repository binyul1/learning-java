FROM eclipse-temurin:17-jre
WORKDIR /app
COPY target/java-devops-demo-1.0.0.jar .
EXPOSE 8080
CMD ["java", "-jar", "java-devops-demo-1.0.0.jar"]
