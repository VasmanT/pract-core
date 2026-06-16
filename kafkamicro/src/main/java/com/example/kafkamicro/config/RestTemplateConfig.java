package com.example.kafkamicro.config;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.boot.web.client.RestTemplateBuilder;
import org.springframework.web.client.RestTemplate;

import java.time.Duration;

/**
 * Конфигурация HTTP клиента для общения с dbmicro
 */
@Configuration
public class RestTemplateConfig {

    @Bean
    public RestTemplate restTemplate(RestTemplateBuilder builder) {
        return builder
                // Таймаут на установку соединения (5 секунд)
                .setConnectTimeout(Duration.ofSeconds(5))
                // Таймаут на чтение ответа (10 секунд)
                .setReadTimeout(Duration.ofSeconds(10))
                .build();
    }
}