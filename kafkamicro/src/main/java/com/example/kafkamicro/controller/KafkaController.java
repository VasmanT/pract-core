//package com.example.kafkamicro.controller;
//
//import com.example.kafkamicro.dto.MessageResponse;
//import com.example.kafkamicro.dto.MessageRequest;
//import com.example.kafkamicro.service.KafkaConsumerService;
//import com.example.kafkamicro.service.KafkaProducerService;
//import io.swagger.v3.oas.annotations.Operation;
//import io.swagger.v3.oas.annotations.Parameter;
//import io.swagger.v3.oas.annotations.tags.Tag;
//import jakarta.validation.Valid;
//import lombok.RequiredArgsConstructor;
//import lombok.extern.slf4j.Slf4j;
//import org.springframework.http.HttpStatus;
//import org.springframework.http.ResponseEntity;
//import org.springframework.web.bind.annotation.*;
//
//import java.time.LocalDateTime;
//import java.util.List;
//import java.util.Map;
//
//@RestController
//@RequestMapping("/api/kafka")
//@RequiredArgsConstructor
//@Slf4j
//@Tag(name = "Kafka Microservice", description = "API для работы с Kafka")
//public class KafkaController {
//
//    private final KafkaConsumerService consumerService;
//    private final KafkaProducerService producerService;
//
//    @GetMapping("/messages")
//    @Operation(summary = "Получить все сообщения из кэша Kafka")
//    public ResponseEntity<MessageResponse> getAllMessages() {
//        log.info("GET запрос - получение всех сообщений из Kafka");
//
//        List<String> messages = consumerService.getAllMessages();
//
//        MessageResponse response = MessageResponse.builder()
//                .messages(messages)
//                .count(messages.size())
//                .timestamp(LocalDateTime.now())
//                .topic("myapp-topic")
//                .build();
//
//        return ResponseEntity.ok(response);
//    }
//
//    @GetMapping("/messages/last")
//    @Operation(summary = "Получить последние N сообщений")
//    public ResponseEntity<List<String>> getLastMessages(
//            @Parameter(description = "Количество сообщений")
//            @RequestParam(defaultValue = "10") int count) {
//
//        List<String> lastMessages = consumerService.getLastMessages(count);
//        return ResponseEntity.ok(lastMessages);
//    }
//
//    @PostMapping("/send")
//    @Operation(summary = "Отправить сообщение в Kafka")
//    public ResponseEntity<Map<String, String>> sendMessage(@Valid @RequestBody MessageRequest request) {
//        log.info("POST запрос - отправка сообщения в Kafka: {}", request.getMessage());
//
//        if (request.getKey() != null && !request.getKey().isEmpty()) {
//            producerService.sendMessageWithKey(request.getKey(), request.getMessage());
//        } else {
//            producerService.sendMessage(request.getMessage());
//        }
//
//        return ResponseEntity.status(HttpStatus.CREATED)
//                .body(Map.of("status", "success", "message", "Сообщение отправлено"));
//    }
//
//    @PostMapping("/send/batch")
//    @Operation(summary = "Отправить несколько сообщений в Kafka")
//    public ResponseEntity<Map<String, String>> sendBatchMessages(@RequestBody List<String> messages) {
//        log.info("POST запрос - отправка {} сообщений в Kafka", messages.size());
//
//        for (String message : messages) {
//            producerService.sendMessage(message);
//        }
//
//        return ResponseEntity.status(HttpStatus.CREATED)
//                .body(Map.of("status", "success", "count", String.valueOf(messages.size())));
//    }
//
//    @DeleteMapping("/clear")
//    @Operation(summary = "Очистить кэш сообщений")
//    public ResponseEntity<Map<String, String>> clearCache() {
//        consumerService.clearMessages();
//        return ResponseEntity.ok(Map.of("status", "success", "message", "Кэш очищен"));
//    }
//
//    @GetMapping("/stats")
//    @Operation(summary = "Получить статистику")
//    public ResponseEntity<Map<String, Object>> getStats() {
//        return ResponseEntity.ok(Map.of(
//                "totalMessagesReceived", consumerService.getMessageCount(),
//                "currentCacheSize", consumerService.getCacheSize(),
//                "timestamp", LocalDateTime.now()
//        ));
//    }
//}