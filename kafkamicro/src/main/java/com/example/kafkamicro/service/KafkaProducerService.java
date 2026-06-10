package com.example.kafkamicro.service;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
@Slf4j
public class KafkaProducerService {

    private final KafkaTemplate<String, String> kafkaTemplate;

    @Value("${kafka.topics.input-topic:myapp-topic}")
    private String topic;

    public void sendMessage(String message) {
        log.info("Отправка сообщения в топик {}: {}", topic, message);
        kafkaTemplate.send(topic, message);
    }

    public void sendMessageWithKey(String key, String message) {
        log.info("Отправка сообщения с ключом {} в топик {}: {}", key, topic, message);
        kafkaTemplate.send(topic, key, message);
    }
}