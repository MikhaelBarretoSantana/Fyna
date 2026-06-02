package com.fyna.Fyna;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.retry.annotation.EnableRetry;
import org.springframework.scheduling.annotation.EnableAsync;
import org.springframework.scheduling.annotation.EnableScheduling;

@EnableAsync
@EnableScheduling
@EnableRetry
@SpringBootApplication
public class FynaApplication {

	public static void main(String[] args) {
		SpringApplication.run(FynaApplication.class, args);
	}

}
