package com.example.practice.config;

import com.example.practice.dto.PlayerCommand;
import org.apache.kafka.clients.producer.ProducerConfig;
import org.apache.kafka.common.serialization.StringSerializer;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.kafka.core.DefaultKafkaProducerFactory;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.kafka.core.ProducerFactory;
import org.springframework.kafka.support.serializer.JsonSerializer;

import java.util.HashMap;
import java.util.Map;

@Configuration
public class KafkaProducerConfig {

    @Value("${spring.kafka.bootstrap-servers:localhost:9092}")
    private String bootstrapServers;

    @Bean
    public ProducerFactory<String, PlayerCommand> producerFactory() {
        Map<String, Object> config = new HashMap<>();

        // Адрес Kafka брокера
        config.put(ProducerConfig.BOOTSTRAP_SERVERS_CONFIG, bootstrapServers);

        // Сериализаторы: ключ - String, значение - JSON
        config.put(ProducerConfig.KEY_SERIALIZER_CLASS_CONFIG, StringSerializer.class);
        config.put(ProducerConfig.VALUE_SERIALIZER_CLASS_CONFIG, JsonSerializer.class);

        // Настройки надежности
        config.put(ProducerConfig.ACKS_CONFIG, "all");           // Ждем подтверждения от всех реплик
        config.put(ProducerConfig.RETRIES_CONFIG, 3);            // 3 попытки при ошибке
        config.put(ProducerConfig.ENABLE_IDEMPOTENCE_CONFIG, true); // Идемпотентность

        return new DefaultKafkaProducerFactory<>(config);
    }

    @Bean
    public KafkaTemplate<String, PlayerCommand> kafkaTemplate() {
        return new KafkaTemplate<>(producerFactory());
    }
}