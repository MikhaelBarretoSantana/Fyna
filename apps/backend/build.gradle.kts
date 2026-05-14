plugins {
	java
	id("org.springframework.boot") version "4.0.2"
	id("io.spring.dependency-management") version "1.1.7"
}

group = "com.fyna"
version = "0.0.1-SNAPSHOT"
description = "Finance AI APP"

java {
	toolchain {
		languageVersion = JavaLanguageVersion.of(21)
	}
}

configurations {
	compileOnly {
		extendsFrom(configurations.annotationProcessor.get())
	}
}

repositories {
	mavenCentral()
}

dependencies {
	// Spring Boot Starters
	implementation("org.springframework.boot:spring-boot-starter-web")
	implementation("org.springframework.boot:spring-boot-starter-websocket")
	implementation("org.springframework.boot:spring-boot-starter-actuator")
	implementation("org.springframework.boot:spring-boot-starter-data-jpa")
	implementation("org.springframework.boot:spring-boot-starter-data-redis")
	implementation("org.springframework.boot:spring-boot-starter-security")
	implementation("org.springframework.boot:spring-boot-starter-validation")
	
	// Database
	implementation("org.springframework.boot:spring-boot-starter-flyway")
	runtimeOnly("org.postgresql:postgresql")
	runtimeOnly("org.flywaydb:flyway-core")
	runtimeOnly("org.flywaydb:flyway-database-postgresql")
	
	// API Documentation
	implementation("org.springdoc:springdoc-openapi-starter-webmvc-ui:2.3.0")
	
	// JWT Authentication
	implementation("io.jsonwebtoken:jjwt-api:0.12.5")
	runtimeOnly("io.jsonwebtoken:jjwt-impl:0.12.5")
	runtimeOnly("io.jsonwebtoken:jjwt-jackson:0.12.5")
	
	// Mapping & Utilities
	implementation("org.mapstruct:mapstruct:1.5.5.Final")
	implementation("org.apache.commons:commons-lang3:3.14.0")

	// Firebase Cloud Messaging (push notifications)
	implementation("com.google.firebase:firebase-admin:9.3.0")
	
	// Lombok
	compileOnly("org.projectlombok:lombok")
	annotationProcessor("org.projectlombok:lombok")
	annotationProcessor("org.mapstruct:mapstruct-processor:1.5.5.Final")
	annotationProcessor("org.projectlombok:lombok-mapstruct-binding:0.2.0")
	
	// Development Tools
	developmentOnly("org.springframework.boot:spring-boot-devtools")
	
	// Testing
	testImplementation("org.springframework.boot:spring-boot-starter-test")
	testImplementation("org.springframework.security:spring-security-test")
	testImplementation("org.testcontainers:testcontainers:1.19.7")
	testImplementation("org.testcontainers:junit-jupiter:1.19.7")
	testImplementation("org.testcontainers:postgresql:1.19.7")
	testRuntimeOnly("org.junit.platform:junit-platform-launcher")
}

tasks.withType<Test> {
	useJUnitPlatform()
}
