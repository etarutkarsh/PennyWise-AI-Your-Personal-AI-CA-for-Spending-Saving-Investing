package com.pennywise;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.scheduling.annotation.EnableAsync;
import org.springframework.scheduling.annotation.EnableScheduling;

/**
 * PennyWise AI - Personal AI CA for Spending, Saving & Investing.
 * Entry point for the Spring Boot backend.
 */
@SpringBootApplication
@EnableScheduling
@EnableAsync
public class PennywiseApplication {

    public static void main(String[] args) {
        SpringApplication.run(PennywiseApplication.class, args);
    }
}
