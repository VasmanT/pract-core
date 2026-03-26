package com.example.practice.controller;

import com.example.practice.model.Player;
import org.springframework.boot.web.client.RestTemplateBuilder;
import org.springframework.http.*;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.client.HttpClientErrorException;
import org.springframework.web.client.ResourceAccessException;
import org.springframework.web.client.RestTemplate;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.time.Duration;
import java.util.Arrays;
import java.util.Collections;
import java.util.List;

import static org.springframework.http.HttpMethod.*;
import static org.springframework.http.HttpStatus.*;
import static org.springframework.http.MediaType.*;
import static org.springframework.http.ResponseEntity.*;

@RestController
@RequestMapping("/api/external-players")
public class ApiClientController {

    private static final Logger log = LoggerFactory.getLogger(ApiClientController.class);

    private final RestTemplate restTemplate;
    private final String externalApiUrl = "http://host.docker.internal:8096/api/players";

    public ApiClientController(RestTemplateBuilder restTemplateBuilder) {
        this.restTemplate = restTemplateBuilder
                .setConnectTimeout(Duration.ofSeconds(5))
                .setReadTimeout(Duration.ofSeconds(10))
                .build();
    }

    // GET all - получение всех игроков
    @GetMapping
    public ResponseEntity<?> getUsersFromExternalApp() {
        log.info("Вызов внешнего API для получения всех игроков: {}", externalApiUrl);

        try {
            var response = restTemplate.getForEntity(externalApiUrl, Player[].class);
            log.info("Статус ответа от внешнего API: {}", response.getStatusCode());

            List<Player> players = response.getBody() != null
                    ? Arrays.asList(response.getBody())
                    : Collections.emptyList();

            if (response.getStatusCode().is2xxSuccessful()) {
                return ok(players);
            } else {
                return status(response.getStatusCode())
                        .body("Внешний сервис вернул статус: " + response.getStatusCode());
            }

        } catch (ResourceAccessException e) {
            log.error("Ошибка подключения к внешнему API: {}", e.getMessage());
            return status(SERVICE_UNAVAILABLE)
                    .body("Не удалось подключиться к внешнему сервису");
        } catch (Exception e) {
            log.error("Ошибка при вызове внешнего API: {}", e.getMessage());
            return status(INTERNAL_SERVER_ERROR)
                    .body("Внутренняя ошибка сервера");
        }
    }

    // GET by ID - получение одного игрока
    @GetMapping("/{id}")
    public ResponseEntity<?> getOneUserFromExternalApp(@PathVariable Long id) {
        var url = externalApiUrl + "/" + id;
        log.info("Вызов внешнего API для получения игрока с id {}: {}", id, url);

        try {
            var response = restTemplate.getForEntity(url, Player.class);

            if (response.getStatusCode().is2xxSuccessful() && response.getBody() != null) {
                log.info("Игрок с id {} успешно получен", id);
                return ok(response.getBody());
            }

            return status(response.getStatusCode())
                    .body("Внешний сервис вернул статус: " + response.getStatusCode());

        } catch (HttpClientErrorException.NotFound e) {
            log.warn("Игрок с id {} не найден", id);
            return status(NOT_FOUND)
                    .body("Игрок с id " + id + " не найден");
        } catch (ResourceAccessException e) {
            log.error("Ошибка подключения: {}", e.getMessage());
            return status(SERVICE_UNAVAILABLE)
                    .body("Не удалось подключиться к внешнему сервису");
        } catch (Exception e) {
            log.error("Ошибка при получении игрока с id {}: {}", id, e.getMessage());
            return status(INTERNAL_SERVER_ERROR)
                    .body("Внутренняя ошибка сервера");
        }
    }

    // POST - создание нового игрока
    @PostMapping
    public ResponseEntity<?> createUserInExternalApp(@RequestBody Player player) {
        log.info("Вызов внешнего API для создания нового игрока: {}", externalApiUrl);
        log.debug("Данные нового игрока: {}", player);

        try {
            var headers = new HttpHeaders();
            headers.setContentType(APPLICATION_JSON);

            var request = new HttpEntity<>(player, headers);

            var response = restTemplate.postForEntity(
                    externalApiUrl,
                    request,
                    Player.class
            );

            log.info("Статус ответа от внешнего API при создании: {}", response.getStatusCode());

            if (response.getStatusCode() == CREATED || response.getStatusCode().is2xxSuccessful()) {
                log.info("Игрок успешно создан с id: {}",
//                        response.getBody() != null ? response.getBody().getId() : "unknown");
                        response.getBody() != null ? response.getBody().id() : "unknown");
                return status(CREATED).body(response.getBody());
            } else {
                return status(response.getStatusCode())
                        .body("Внешний сервис вернул статус: " + response.getStatusCode());
            }

        } catch (HttpClientErrorException.BadRequest e) {
            log.error("Неверные данные при создании игрока: {}", e.getResponseBodyAsString());
            return status(BAD_REQUEST)
                    .body("Неверные данные: " + e.getResponseBodyAsString());
        } catch (HttpClientErrorException.Conflict e) {
            log.error("Конфликт при создании игрока: {}", e.getResponseBodyAsString());
            return status(CONFLICT)
                    .body("Игрок уже существует: " + e.getResponseBodyAsString());
        } catch (ResourceAccessException e) {
            log.error("Ошибка подключения при создании: {}", e.getMessage());
            return status(SERVICE_UNAVAILABLE)
                    .body("Не удалось подключиться к внешнему сервису");
        } catch (Exception e) {
            log.error("Ошибка при создании игрока: {}", e.getMessage());
            return status(INTERNAL_SERVER_ERROR)
                    .body("Внутренняя ошибка сервера");
        }
    }

    // PUT - полное обновление игрока
    @PutMapping("/{id}")
    public ResponseEntity<?> updateUserInExternalApp(@PathVariable Long id, @RequestBody Player player) {
        var url = externalApiUrl + "/" + id;
        log.info("Вызов внешнего API для обновления игрока с id {}: {}", id, url);
        log.debug("Данные для обновления: {}", player);

        try {
            var headers = new HttpHeaders();
            headers.setContentType(APPLICATION_JSON);

            var request = new HttpEntity<>(player, headers);

            var response = restTemplate.exchange(
                    url,
                    PUT,
                    request,
                    Player.class
            );

            log.info("Статус ответа от внешнего API при обновлении: {}", response.getStatusCode());

            if (response.getStatusCode().is2xxSuccessful()) {
                log.info("Игрок с id {} успешно обновлен", id);
                return ok(response.getBody() != null ? response.getBody() : "Игрок успешно обновлен");
            } else {
                return status(response.getStatusCode())
                        .body("Внешний сервис вернул статус: " + response.getStatusCode());
            }

        } catch (HttpClientErrorException.NotFound e) {
            log.warn("Игрок с id {} не найден для обновления", id);
            return status(NOT_FOUND)
                    .body("Игрок с id " + id + " не найден");
        } catch (HttpClientErrorException.BadRequest e) {
            log.error("Неверные данные при обновлении игрока {}: {}", id, e.getResponseBodyAsString());
            return status(BAD_REQUEST)
                    .body("Неверные данные: " + e.getResponseBodyAsString());
        } catch (ResourceAccessException e) {
            log.error("Ошибка подключения при обновлении: {}", e.getMessage());
            return status(SERVICE_UNAVAILABLE)
                    .body("Не удалось подключиться к внешнему сервису");
        } catch (Exception e) {
            log.error("Ошибка при обновлении игрока с id {}: {}", id, e.getMessage());
            return status(INTERNAL_SERVER_ERROR)
                    .body("Внутренняя ошибка сервера");
        }
    }

    // PATCH - частичное обновление игрока
    @PatchMapping("/{id}")
    public ResponseEntity<?> partialUpdateUserInExternalApp(@PathVariable Long id, @RequestBody Player player) {
        var url = externalApiUrl + "/" + id;
        log.info("Вызов внешнего API для частичного обновления игрока с id {}: {}", id, url);

        try {
            var headers = new HttpHeaders();
            headers.setContentType(APPLICATION_JSON);

            var request = new HttpEntity<>(player, headers);

            var response = restTemplate.exchange(
                    url,
                    PATCH,
                    request,
                    Player.class
            );

            log.info("Статус ответа от внешнего API при частичном обновлении: {}", response.getStatusCode());

            if (response.getStatusCode().is2xxSuccessful()) {
                log.info("Игрок с id {} успешно частично обновлен", id);
                return ok(response.getBody() != null ? response.getBody() : "Игрок успешно обновлен");
            } else {
                return status(response.getStatusCode())
                        .body("Внешний сервис вернул статус: " + response.getStatusCode());
            }

        } catch (HttpClientErrorException.NotFound e) {
            log.warn("Игрок с id {} не найден для частичного обновления", id);
            return status(NOT_FOUND)
                    .body("Игрок с id " + id + " не найден");
        } catch (HttpClientErrorException.BadRequest e) {
            log.error("Неверные данные при частичном обновлении: {}", e.getResponseBodyAsString());
            return status(BAD_REQUEST)
                    .body("Неверные данные: " + e.getResponseBodyAsString());
        } catch (Exception e) {
            log.error("Ошибка при частичном обновлении игрока с id {}: {}", id, e.getMessage());
            return status(INTERNAL_SERVER_ERROR)
                    .body("Внутренняя ошибка сервера");
        }
    }

    // DELETE - удаление игрока
    @DeleteMapping("/{id}")
    public ResponseEntity<?> deleteUserFromExternalApp(@PathVariable Long id) {
        var url = externalApiUrl + "/" + id;
        log.info("Вызов внешнего API для удаления игрока с id {}: {}", id, url);

        try {
            var headers = new HttpHeaders();
            HttpEntity<?> request = new HttpEntity<>(headers);

            var response = restTemplate.exchange(
                    url,
                    DELETE,
                    request,
                    Void.class
            );

            log.info("Статус ответа от внешнего API при удалении: {}", response.getStatusCode());

            if (response.getStatusCode() == NO_CONTENT || response.getStatusCode().is2xxSuccessful()) {
                log.info("Игрок с id {} успешно удален", id);
                return noContent().build();
            } else {
                return status(response.getStatusCode())
                        .body("Внешний сервис вернул статус: " + response.getStatusCode());
            }

        } catch (HttpClientErrorException.NotFound e) {
            log.warn("Игрок с id {} не найден для удаления", id);
            return status(NOT_FOUND)
                    .body("Игрок с id " + id + " не найден");
        } catch (ResourceAccessException e) {
            log.error("Ошибка подключения при удалении: {}", e.getMessage());
            return status(SERVICE_UNAVAILABLE)
                    .body("Не удалось подключиться к внешнему сервису");
        } catch (Exception e) {
            log.error("Ошибка при удалении игрока с id {}: {}", id, e.getMessage());
            return status(INTERNAL_SERVER_ERROR)
                    .body("Внутренняя ошибка сервера");
        }
    }

    // DELETE all - удаление всех игроков (если API поддерживает)
    @DeleteMapping
    public ResponseEntity<?> deleteAllUsersFromExternalApp() {
        log.info("Вызов внешнего API для удаления всех игроков: {}", externalApiUrl);

        try {
            var headers = new HttpHeaders();
            HttpEntity<?> request = new HttpEntity<>(headers);

            var response = restTemplate.exchange(
                    externalApiUrl,
                    DELETE,
                    request,
                    Void.class
            );

            log.info("Статус ответа от внешнего API при удалении всех: {}", response.getStatusCode());

            if (response.getStatusCode() == NO_CONTENT || response.getStatusCode().is2xxSuccessful()) {
                log.info("Все игроки успешно удалены");
                return noContent().build();
            } else {
                return status(response.getStatusCode())
                        .body("Внешний сервис вернул статус: " + response.getStatusCode());
            }

        } catch (ResourceAccessException e) {
            log.error("Ошибка подключения при удалении всех: {}", e.getMessage());
            return status(SERVICE_UNAVAILABLE)
                    .body("Не удалось подключиться к внешнему сервису");
        } catch (Exception e) {
            log.error("Ошибка при удалении всех игроков: {}", e.getMessage());
            return status(INTERNAL_SERVER_ERROR)
                    .body("Внутренняя ошибка сервера");
        }
    }
}