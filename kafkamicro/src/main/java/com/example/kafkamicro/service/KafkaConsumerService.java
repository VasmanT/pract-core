//package com.example.kafkamicro.service;
//
//import lombok.extern.slf4j.Slf4j;
//import org.springframework.beans.factory.annotation.Value;
//import org.springframework.kafka.annotation.KafkaListener;
//import org.springframework.kafka.support.Acknowledgment;
//import org.springframework.stereotype.Service;
//
//import java.util.ArrayList;
//import java.util.List;
//import java.util.concurrent.ConcurrentLinkedQueue;
//import java.util.concurrent.atomic.AtomicInteger;
//
//@Service
//@Slf4j
//public class KafkaConsumerService {
//
//    private final ConcurrentLinkedQueue<String> receivedMessages = new ConcurrentLinkedQueue<>();
//    private final AtomicInteger messageCounter = new AtomicInteger(0);
//
//    @Value("${kafka.topics.input-topic:myapp-topic}")
//    private String inputTopic;
//
//    @Value("${kafka.cache.max-size:10000}")
//    private int maxCacheSize;
//
//    @KafkaListener(
//            topics = "${kafka.topics.input-topic}",
//            groupId = "${spring.kafka.consumer.group-id}",
//            containerFactory = "kafkaListenerContainerFactory"
//    )
//    public void consume(String message, Acknowledgment acknowledgment) {
//        try {
//            log.debug("Получено сообщение из топика {}: {}", inputTopic, message);
//
//            // Добавляем сообщение в очередь
//            receivedMessages.offer(message);
//            messageCounter.incrementAndGet();
//
//            // Ограничиваем размер кэша
//            while (receivedMessages.size() > maxCacheSize) {
//                receivedMessages.poll();
//            }
//
//            // Подтверждаем обработку сообщения
//            acknowledgment.acknowledge();
//
//        } catch (Exception e) {
//            log.error("Ошибка при обработке сообщения: {}", message, e);
//            // В случае ошибки не подтверждаем - сообщение будет обработано снова
//        }
//    }
//
//    public List<String> getAllMessages() {
//        return new ArrayList<>(receivedMessages);
//    }
//
//    public List<String> getLastMessages(int count) {
//        List<String> allMessages = getAllMessages();
//        int startIndex = Math.max(0, allMessages.size() - count);
//        return allMessages.subList(startIndex, allMessages.size());
//    }
//
//    public void clearMessages() {
//        receivedMessages.clear();
//        messageCounter.set(0);
//        log.info("Кэш сообщений очищен");
//    }
//
//    public int getMessageCount() {
//        return messageCounter.get();
//    }
//
//    public int getCacheSize() {
//        return receivedMessages.size();
//    }
//}