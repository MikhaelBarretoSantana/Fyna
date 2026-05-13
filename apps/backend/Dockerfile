# ── Build stage ─────────────────────────────────────────────
FROM eclipse-temurin:21-jdk-alpine AS builder
WORKDIR /app

COPY gradlew gradlew.bat ./
COPY gradle gradle/
COPY build.gradle.kts settings.gradle.kts ./
RUN chmod +x gradlew

# Baixa dependências em camada separada (cache eficiente)
RUN ./gradlew dependencies --no-daemon -q

COPY src src/
RUN ./gradlew bootJar --no-daemon -x test

# ── Runtime stage ────────────────────────────────────────────
FROM eclipse-temurin:21-jre-alpine
WORKDIR /app

COPY --from=builder /app/build/libs/*.jar app.jar

EXPOSE 8080
ENTRYPOINT ["java", "-jar", "app.jar"]
