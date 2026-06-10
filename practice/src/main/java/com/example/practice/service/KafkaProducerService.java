package com.example.practice.service;

import org.springframework.kafka.core.KafkaTemplate;

public class KafkaProducerService {
    KafkaTemplate<String, String> kafkaTemplate;

   public KafkaProducerService(KafkaTemplate<String, String> kafkaTemplate) {
       this.kafkaTemplate = kafkaTemplate;
   }

   public void sendMessage(String topic, String message) {
       kafkaTemplate.send(topic, message);
   }

}
