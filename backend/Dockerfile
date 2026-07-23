# --- Build stage -------------------------------------------------------
# Uses a Maven+JDK17 image so you don't need Maven or JDK17 installed
# on your host machine at all.
FROM maven:3.9-eclipse-temurin-17 AS build
WORKDIR /app

# Cache dependencies separately from source so `docker compose up` rebuilds
# are fast when you're only changing Java files.
COPY pom.xml .
RUN mvn -B dependency:go-offline

COPY src ./src
RUN mvn -B package -DskipTests

# --- Runtime stage -------------------------------------------------------
FROM eclipse-temurin:17-jre-alpine
WORKDIR /app

COPY --from=build /app/target/pennywise-backend.jar app.jar

EXPOSE 8080
ENTRYPOINT ["java", "-jar", "app.jar"]
