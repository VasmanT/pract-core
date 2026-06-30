package com.example.practice.controller;

import com.example.practice.dto.PlayerCommand;
import com.example.practice.model.Player;
import com.example.practice.service.KafkaCommandProducer;
import org.springframework.boot.web.client.RestTemplateBuilder;
import org.springframework.http.*;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.client.HttpClientErrorException;
import org.springframework.web.client.ResourceAccessException;
import org.springframework.web.client.RestTemplate;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.time.Duration;
import java.util.*;

import static org.springframework.http.HttpStatus.*;
import static org.springframework.http.ResponseEntity.*;

@RestController
@RequestMapping("/api/external-players")
public class ApiClientController {

    private static final Logger log = LoggerFactory.getLogger(ApiClientController.class);

    private final RestTemplate restTemplate;
    private final KafkaCommandProducer kafkaProducer;
    private final String externalApiUrl = "http://host.docker.internal:8096/api/players";

    public ApiClientController(RestTemplateBuilder restTemplateBuilder,
                               KafkaCommandProducer kafkaProducer) {
        this.restTemplate = restTemplateBuilder
                .setConnectTimeout(Duration.ofSeconds(5))
                .setReadTimeout(Duration.ofSeconds(10))
                .build();
        this.kafkaProducer = kafkaProducer;
    }

    // ==================== GET запросы - через RestTemplate (синхронно) ====================

    @GetMapping
    public ResponseEntity<?> getUsersFromExternalApp() {
        log.info("GET - прямое обращение к dbmicro: {}", externalApiUrl);

        try {
//            var response = restTemplate.getForEntity(externalApiUrl, Player[].class);
            ResponseEntity<Player[]> response = restTemplate.getForEntity(externalApiUrl, Player[].class);
            List<Player> players = response.getBody() != null
                    ? Arrays.asList(response.getBody())
                    : Collections.emptyList();
            return ok(players);

        } catch (ResourceAccessException e) {
            log.error("Ошибка подключения: {}", e.getMessage());
            return status(SERVICE_UNAVAILABLE)
                    .body("Не удалось подключиться к сервису БД");
        } catch (Exception e) {
            log.error("Ошибка: {}", e.getMessage());
            return status(INTERNAL_SERVER_ERROR)
                    .body("Внутренняя ошибка сервера");
        }
    }

    @GetMapping("/{id}")
    public ResponseEntity<?> getOneUserFromExternalApp(@PathVariable Long id) {
        var url = externalApiUrl + "/" + id;
        log.info("GET - получение игрока {} через RestTemplate", id);

        try {
            var response = restTemplate.getForEntity(url, Player.class);
            if (response.getStatusCode().is2xxSuccessful() && response.getBody() != null) {
                return ok(response.getBody());
            }
            return status(response.getStatusCode())
                    .body("Сервис БД вернул статус: " + response.getStatusCode());

        } catch (HttpClientErrorException.NotFound e) {
            return status(NOT_FOUND).body("Игрок с id " + id + " не найден");
        } catch (ResourceAccessException e) {
            return status(SERVICE_UNAVAILABLE).body("Сервис БД недоступен");
        } catch (Exception e) {
            return status(INTERNAL_SERVER_ERROR).body("Внутренняя ошибка");
        }
    }

    // ==================== CREATE - через Kafka ====================

    @PostMapping
    public ResponseEntity<?> createUserAsync(@RequestBody Player player) {
        log.info("POST - отправка команды CREATE в Kafka");

        // Отправляем команду в Kafka
        PlayerCommand command = PlayerCommand.create(player); // command, объект типа PlayerCommand c определёнными параметрами. Одним из них является команда create
        boolean sent = kafkaProducer.sendCommand(command); // вызов метода sC объекта kP типа KPC с передаваемым параметром command

        if (!sent) {
            return status(SERVICE_UNAVAILABLE)
                    .body(Map.of(
                            "status", "error",
                            "message", "Не удалось отправить команду в очередь"
                    ));
        }

        // Возвращаем мгновенный ответ
        return status(ACCEPTED).body(Map.of(
                "status", "queued",
                "message", "Задача на создание игрока поставлена в очередь",
                "requestId", command.getRequestId(),
                "command", "CREATE"
        ));
    }

    // ==================== UPDATE - через Kafka ====================

    @PutMapping("/{id}")
    public ResponseEntity<?> updateUserAsync(@PathVariable Long id, @RequestBody Player player) {
        log.info("PUT - отправка команды UPDATE в Kafka для id={}", id);

        // Убедимся, что ID в пути и в теле совпадают
        if (!id.equals(player.id())) {
            return status(BAD_REQUEST).body(Map.of(
                    "status", "error",
                    "message", "ID в пути и теле запроса не совпадают"
            ));
        }

        PlayerCommand command = PlayerCommand.update(id, player);
        boolean sent = kafkaProducer.sendCommand(command);

        if (!sent) {
            return status(SERVICE_UNAVAILABLE)
                    .body(Map.of("status", "error", "message", "Очередь недоступна"));
        }

        return status(ACCEPTED).body(Map.of(
                "status", "queued",
                "message", "Задача на обновление игрока поставлена в очередь",
                "requestId", command.getRequestId(),
                "command", "UPDATE",
                "playerId", id
        ));
    }

    // ==================== DELETE - через Kafka ====================

    @DeleteMapping("/{id}")
    public ResponseEntity<?> deleteUserAsync(@PathVariable Long id) {
        log.info("DELETE - отправка команды DELETE в Kafka для id={}", id);

        PlayerCommand command = PlayerCommand.delete(id);
        boolean sent = kafkaProducer.sendCommand(command);

        if (!sent) {
            return status(SERVICE_UNAVAILABLE)
                    .body(Map.of("status", "error", "message", "Очередь недоступна"));
        }

        return status(ACCEPTED).body(Map.of(
                "status", "queued",
                "message", "Задача на удаление игрока поставлена в очередь",
                "requestId", command.getRequestId(),
                "command", "DELETE",
                "playerId", id
        ));
    }

    // ==================== DELETE ALL - через Kafka ====================


    @DeleteMapping
    public ResponseEntity<?> deleteAllUsersAsync() {
        log.info("DELETE - отправка команды DELETE_ALL в Kafka (пока не поддерживается)");
        PlayerCommand command = PlayerCommand.delete(null);
        boolean sent = kafkaProducer.sendCommand(command);
        if (!sent) {
            return status(SERVICE_UNAVAILABLE)
                    .body(Map.of("status", "error", "message", "Очередь недоступна"));
        }

        return status(ACCEPTED).body(Map.of(
                "status", "queued",
                "message", "Задача на массовое удаление всех игроков поставлена в очередь.",
                "requestId", command.getRequestId(),
                "command", "DELETE"
        ));


        // Для массового удаления лучше отдельная логика
//        return status(NOT_IMPLEMENTED).body(Map.of(
//                "status", "error",
//                "message", "Массовое удаление через очередь пока не реализовано. " +
//                        "Используйте DELETE /{id} для каждого игрока"
//        ));
    }


    // ==================== PATCH - через Kafka ====================

    @PatchMapping("/{id}")
    public ResponseEntity<?> partialUpdateUserAsync(@PathVariable Long id, @RequestBody Player player) {
        log.info("PATCH - частичное обновление через Kafka (преобразуем в UPDATE)");

        // Для partial update отправляем как UPDATE
        PlayerCommand command = PlayerCommand.update(id, player);
        boolean sent = kafkaProducer.sendCommand(command);

        if (!sent) {
            return status(SERVICE_UNAVAILABLE)
                    .body(Map.of("status", "error", "message", "Очередь недоступна"));
        }

        return status(ACCEPTED).body(Map.of(
                "status", "queued",
                "message", "Задача на частичное обновление поставлена в очередь",
                "requestId", command.getRequestId()
        ));
    }
}


//package com.example.practice.controller;
//
//import com.example.practice.model.Player;
//import org.springframework.beans.factory.annotation.Autowired;
//import org.springframework.boot.web.client.RestTemplateBuilder;
//import org.springframework.http.*;
//import org.springframework.kafka.core.KafkaTemplate;
//import org.springframework.web.bind.annotation.*;
//import org.springframework.web.client.HttpClientErrorException;
//import org.springframework.web.client.ResourceAccessException;
//import org.springframework.web.client.RestTemplate;
//import org.slf4j.Logger;
//import org.slf4j.LoggerFactory;
//
//import java.time.Duration;
//import java.util.Arrays;
//import java.util.Collections;
//import java.util.List;
//
//import static org.springframework.http.HttpMethod.*;
//import static org.springframework.http.HttpStatus.*;
//import static org.springframework.http.MediaType.*;
//import static org.springframework.http.ResponseEntity.*;
//
//@RestController
//@RequestMapping("/api/external-players")
//public class ApiClientController {
//
//    private static final Logger log = LoggerFactory.getLogger(ApiClientController.class);
//
//    private final RestTemplate restTemplate;
//    private final String externalApiUrl = "http://host.docker.internal:8096/api/players";
////    public final KafkaProducerService kafkaProducerService;
//
//    @Autowired
////    public ApiClientController(RestTemplateBuilder restTemplateBuilder, KafkaProducerService kafkaProducerService) {
//    public ApiClientController(RestTemplateBuilder restTemplateBuilder) {
//        this.restTemplate = restTemplateBuilder
//                .setConnectTimeout(Duration.ofSeconds(5))
//                .setReadTimeout(Duration.ofSeconds(10))
//                .build();
////        this.kafkaProducerService = kafkaProducerService;
//    }
//
//
//
//
//    // GET all - получение всех игроков
//    @GetMapping
//    public ResponseEntity<?> getUsersFromExternalApp() {
//        log.info("Вызов внешнего API для получения всех игроков: {}", externalApiUrl);
//
//        try {
//            var response = restTemplate.getForEntity(externalApiUrl, Player[].class);
//            log.info("Статус ответа от внешнего API: {}", response.getStatusCode());
//
//            List<Player> players = response.getBody() != null
//                    ? Arrays.asList(response.getBody())
//                    : Collections.emptyList();
//
//            if (response.getStatusCode().is2xxSuccessful()) {
//                return ok(players);
//            } else {
//                return status(response.getStatusCode())
//                        .body("Внешний сервис вернул статус: " + response.getStatusCode());
//            }
//
//        } catch (ResourceAccessException e) {
//            log.error("Ошибка подключения к внешнему API: {}", e.getMessage());
//            return status(SERVICE_UNAVAILABLE)
//                    .body("Не удалось подключиться к внешнему сервису");
//        } catch (Exception e) {
//            log.error("Ошибка при вызове внешнего API: {}", e.getMessage());
//            return status(INTERNAL_SERVER_ERROR)
//                    .body("Внутренняя ошибка сервера");
//        }
//    }
//
//    // GET by ID - получение одного игрока
//    @GetMapping("/{id}")
//    public ResponseEntity<?> getOneUserFromExternalApp(@PathVariable Long id) {
//        var url = externalApiUrl + "/" + id;
//        log.info("Вызов внешнего API для получения игрока с id {}: {}", id, url);
//
//        try {
//            var response = restTemplate.getForEntity(url, Player.class);
//
//            if (response.getStatusCode().is2xxSuccessful() && response.getBody() != null) {
//                log.info("Игрок с id {} успешно получен", id);
//                return ok(response.getBody());
//            }
//
//            return status(response.getStatusCode())
//                    .body("Внешний сервис вернул статус: " + response.getStatusCode());
//
//        } catch (HttpClientErrorException.NotFound e) {
//            log.warn("Игрок с id {} не найден", id);
//            return status(NOT_FOUND)
//                    .body("Игрок с id " + id + " не найден");
//        } catch (ResourceAccessException e) {
//            log.error("Ошибка подключения: {}", e.getMessage());
//            return status(SERVICE_UNAVAILABLE)
//                    .body("Не удалось подключиться к внешнему сервису");
//        } catch (Exception e) {
//            log.error("Ошибка при получении игрока с id {}: {}", id, e.getMessage());
//            return status(INTERNAL_SERVER_ERROR)
//                    .body("Внутренняя ошибка сервера");
//        }
//    }
//
//    // POST - создание нового игрока
//    @PostMapping
//    public ResponseEntity<?> createUserInExternalApp(@RequestBody Player player) {
//        log.info("Вызов внешнего API для создания нового игрока: {}", externalApiUrl);
//        log.debug("Данные нового игрока: {}", player);
//
//
////        return null;
//        try {
//            var headers = new HttpHeaders();
//            headers.setContentType(APPLICATION_JSON);
//
//            var request = new HttpEntity<>(player, headers);
//
//            var response = restTemplate.postForEntity(
//                    externalApiUrl,
//                    request,
//                    Player.class
//            );
//
//            log.info("Статус ответа от внешнего API при создании: {}", response.getStatusCode());
//
//            if (response.getStatusCode() == CREATED || response.getStatusCode().is2xxSuccessful()) {
//                log.info("Игрок успешно создан с id: {}",
//                        response.getBody() != null ? response.getBody().id() : "unknown");
//                return status(CREATED).body(response.getBody());
//            } else {
//                return status(response.getStatusCode())
//                        .body("Внешний сервис вернул статус: " + response.getStatusCode());
//            }
//
//        } catch (HttpClientErrorException.BadRequest e) {
//            log.error("Неверные данные при создании игрока: {}", e.getResponseBodyAsString());
//            return status(BAD_REQUEST)
//                    .body("Неверные данные: " + e.getResponseBodyAsString());
//        } catch (HttpClientErrorException.Conflict e) {
//            log.error("Конфликт при создании игрока: {}", e.getResponseBodyAsString());
//            return status(CONFLICT)
//                    .body("Игрок уже существует: " + e.getResponseBodyAsString());
//        } catch (ResourceAccessException e) {
//            log.error("Ошибка подключения при создании: {}", e.getMessage());
//            return status(SERVICE_UNAVAILABLE)
//                    .body("Не удалось подключиться к внешнему сервису");
//        } catch (Exception e) {
//            log.error("Ошибка при создании игрока: {}", e.getMessage());
//            return status(INTERNAL_SERVER_ERROR)
//                    .body("Внутренняя ошибка сервера");
//        }
//    }
//
//    // PUT - полное обновление игрока
//    @PutMapping("/{id}")
//    public ResponseEntity<?> updateUserInExternalApp(@PathVariable Long id, @RequestBody Player player) {
//        var url = externalApiUrl + "/" + id;
//        log.info("Вызов внешнего API для обновления игрока с id {}: {}", id, url);
//        log.debug("Данные для обновления: {}", player);
//
//        try {
//            var headers = new HttpHeaders();
//            headers.setContentType(APPLICATION_JSON);
//
//            var request = new HttpEntity<>(player, headers);
//
//            var response = restTemplate.exchange(
//                    url,
//                    PUT,
//                    request,
//                    Player.class
//            );
//
//            log.info("Статус ответа от внешнего API при обновлении: {}", response.getStatusCode());
//
//            if (response.getStatusCode().is2xxSuccessful()) {
//                log.info("Игрок с id {} успешно обновлен", id);
//                return ok(response.getBody() != null ? response.getBody() : "Игрок успешно обновлен");
//            } else {
//                return status(response.getStatusCode())
//                        .body("Внешний сервис вернул статус: " + response.getStatusCode());
//            }
//
//        } catch (HttpClientErrorException.NotFound e) {
//            log.warn("Игрок с id {} не найден для обновления", id);
//            return status(NOT_FOUND)
//                    .body("Игрок с id " + id + " не найден");
//        } catch (HttpClientErrorException.BadRequest e) {
//            log.error("Неверные данные при обновлении игрока {}: {}", id, e.getResponseBodyAsString());
//            return status(BAD_REQUEST)
//                    .body("Неверные данные: " + e.getResponseBodyAsString());
//        } catch (ResourceAccessException e) {
//            log.error("Ошибка подключения при обновлении: {}", e.getMessage());
//            return status(SERVICE_UNAVAILABLE)
//                    .body("Не удалось подключиться к внешнему сервису");
//        } catch (Exception e) {
//            log.error("Ошибка при обновлении игрока с id {}: {}", id, e.getMessage());
//            return status(INTERNAL_SERVER_ERROR)
//                    .body("Внутренняя ошибка сервера");
//        }
//    }
//
//    // PATCH - частичное обновление игрока
//    @PatchMapping("/{id}")
//    public ResponseEntity<?> partialUpdateUserInExternalApp(@PathVariable Long id, @RequestBody Player player) {
//        var url = externalApiUrl + "/" + id;
//        log.info("Вызов внешнего API для частичного обновления игрока с id {}: {}", id, url);
//
//        try {
//            var headers = new HttpHeaders();
//            headers.setContentType(APPLICATION_JSON);
//
//            var request = new HttpEntity<>(player, headers);
//
//            var response = restTemplate.exchange(
//                    url,
//                    PATCH,
//                    request,
//                    Player.class
//            );
//
//            log.info("Статус ответа от внешнего API при частичном обновлении: {}", response.getStatusCode());
//
//            if (response.getStatusCode().is2xxSuccessful()) {
//                log.info("Игрок с id {} успешно частично обновлен", id);
//                return ok(response.getBody() != null ? response.getBody() : "Игрок успешно обновлен");
//            } else {
//                return status(response.getStatusCode())
//                        .body("Внешний сервис вернул статус: " + response.getStatusCode());
//            }
//
//        } catch (HttpClientErrorException.NotFound e) {
//            log.warn("Игрок с id {} не найден для частичного обновления", id);
//            return status(NOT_FOUND)
//                    .body("Игрок с id " + id + " не найден");
//        } catch (HttpClientErrorException.BadRequest e) {
//            log.error("Неверные данные при частичном обновлении: {}", e.getResponseBodyAsString());
//            return status(BAD_REQUEST)
//                    .body("Неверные данные: " + e.getResponseBodyAsString());
//        } catch (Exception e) {
//            log.error("Ошибка при частичном обновлении игрока с id {}: {}", id, e.getMessage());
//            return status(INTERNAL_SERVER_ERROR)
//                    .body("Внутренняя ошибка сервера");
//        }
//    }
//
//    // DELETE - удаление игрока
//    @DeleteMapping("/{id}")
//    public ResponseEntity<?> deleteUserFromExternalApp(@PathVariable Long id) {
//        var url = externalApiUrl + "/" + id;
//        log.info("Вызов внешнего API для удаления игрока с id {}: {}", id, url);
//
//        try {
//            var headers = new HttpHeaders();
//            HttpEntity<?> request = new HttpEntity<>(headers);
//
//            var response = restTemplate.exchange(
//                    url,
//                    DELETE,
//                    request,
//                    Void.class
//            );
//
//            log.info("Статус ответа от внешнего API при удалении: {}", response.getStatusCode());
//
//            if (response.getStatusCode() == NO_CONTENT || response.getStatusCode().is2xxSuccessful()) {
//                log.info("Игрок с id {} успешно удален", id);
//                return noContent().build();
//            } else {
//                return status(response.getStatusCode())
//                        .body("Внешний сервис вернул статус: " + response.getStatusCode());
//            }
//
//        } catch (HttpClientErrorException.NotFound e) {
//            log.warn("Игрок с id {} не найден для удаления", id);
//            return status(NOT_FOUND)
//                    .body("Игрок с id " + id + " не найден");
//        } catch (ResourceAccessException e) {
//            log.error("Ошибка подключения при удалении: {}", e.getMessage());
//            return status(SERVICE_UNAVAILABLE)
//                    .body("Не удалось подключиться к внешнему сервису");
//        } catch (Exception e) {
//            log.error("Ошибка при удалении игрока с id {}: {}", id, e.getMessage());
//            return status(INTERNAL_SERVER_ERROR)
//                    .body("Внутренняя ошибка сервера");
//        }
//    }
//
//    // DELETE all - удаление всех игроков (если API поддерживает)
//    @DeleteMapping
//    public ResponseEntity<?> deleteAllUsersFromExternalApp() {
//        log.info("Вызов внешнего API для удаления всех игроков: {}", externalApiUrl);
//
//        try {
//            var headers = new HttpHeaders();
//            HttpEntity<?> request = new HttpEntity<>(headers);
//
//            var response = restTemplate.exchange(
//                    externalApiUrl,
//                    DELETE,
//                    request,
//                    Void.class
//            );
//
//            log.info("Статус ответа от внешнего API при удалении всех: {}", response.getStatusCode());
//
//            if (response.getStatusCode() == NO_CONTENT || response.getStatusCode().is2xxSuccessful()) {
//                log.info("Все игроки успешно удалены");
//                return noContent().build();
//            } else {
//                return status(response.getStatusCode())
//                        .body("Внешний сервис вернул статус: " + response.getStatusCode());
//            }
//
//        } catch (ResourceAccessException e) {
//            log.error("Ошибка подключения при удалении всех: {}", e.getMessage());
//            return status(SERVICE_UNAVAILABLE)
//                    .body("Не удалось подключиться к внешнему сервису");
//        } catch (Exception e) {
//            log.error("Ошибка при удалении всех игроков: {}", e.getMessage());
//            return status(INTERNAL_SERVER_ERROR)
//                    .body("Внутренняя ошибка сервера");
//        }
//    }
//}