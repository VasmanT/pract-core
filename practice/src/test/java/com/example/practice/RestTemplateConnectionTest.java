package com.example.practice;

import org.springframework.web.client.RestTemplate;
import org.springframework.web.client.ResourceAccessException;
import org.springframework.web.client.HttpClientErrorException;
import org.springframework.web.client.RestClientException;
import org.springframework.http.ResponseEntity;
import org.springframework.http.HttpStatus;

public class RestTemplateConnectionTest {

    private static final String BASE_URL = "http://localhost:8089";
    private static final RestTemplate restTemplate = new RestTemplate();

    public static void main(String[] args) {
        System.out.println("🔍 Тестирование подключения к dbmicro...");
        System.out.println("==========================================");

        // Тест 1: Проверка доступности сервера (health check)
        testHealthCheck();

        // Тест 2: Проверка API players
        testPlayersEndpoint();

        // Тест 3: Проверка с таймаутами
        testWithTimeouts();
    }

    private static void testHealthCheck() {
        System.out.println("\n📡 Тест 1: Health Check Endpoint");
        System.out.println("----------------------------------");

        try {
            String healthUrl = BASE_URL + "/api/external-players";
            ResponseEntity<String> response = restTemplate.getForEntity(healthUrl, String.class);

            if (response.getStatusCode() == HttpStatus.OK) {
                System.out.println("✅ Health check успешен!");
                System.out.println("   Статус: " + response.getStatusCode());
                System.out.println("   Ответ: " + response.getBody());
            } else {
                System.out.println("❌ Health check вернул статус: " + response.getStatusCode());
            }
        } catch (ResourceAccessException e) {
            System.out.println("❌ Ошибка подключения: " + e.getMessage());
            System.out.println("   ➡ Сервер dbmicro не запущен или недоступен");
        } catch (HttpClientErrorException.NotFound e) {
            System.out.println("⚠ Health check endpoint не найден (404)");
            System.out.println("   ➡ Рекомендуется добавить @GetMapping('/api/health') в dbmicro");
        } catch (Exception e) {
            System.out.println("❌ Неожиданная ошибка: " + e.getClass().getSimpleName());
            System.out.println("   Сообщение: " + e.getMessage());
        }
    }

    private static void testPlayersEndpoint() {
        System.out.println("\n📡 Тест 2: Players API Endpoint");
        System.out.println("----------------------------------");

        try {
            String playersUrl = BASE_URL + "/api/external-players";

            // Используем exchange для получения полной информации
            ResponseEntity<String> response = restTemplate.getForEntity(playersUrl, String.class);

            System.out.println("✅ Запрос выполнен успешно!");
            System.out.println("   URL: " + playersUrl);
            System.out.println("   Статус: " + response.getStatusCode() + " (" + response.getStatusCode().value() + ")");
            System.out.println("   Заголовки:");
            response.getHeaders().forEach((key, value) ->
                    System.out.println("      " + key + ": " + value));

            // Проверяем тело ответа
            String body = response.getBody();
            if (body != null && !body.isEmpty()) {
                System.out.println("   📦 Размер ответа: " + body.length() + " символов");
                System.out.println("   📦 Первые 100 символов: " +
                        (body.length() > 100 ? body.substring(0, 100) + "..." : body));
            } else {
                System.out.println("   📦 Тело ответа пустое");
            }

        } catch (ResourceAccessException e) {
            System.out.println("❌ Ошибка подключения: " + e.getMessage());
            System.out.println("   ➡ Проверьте:");
            System.out.println("      1. Запущено ли dbmicro: java -jar dbmicro.jar");
            System.out.println("      2. Правильный ли порт: 8091");
            System.out.println("      3. Нет ли брандмауэра");

        } catch (HttpClientErrorException e) {
            System.out.println("❌ HTTP ошибка " + e.getStatusCode() + ":");
            System.out.println("   Статус: " + e.getStatusCode());
            System.out.println("   Сообщение: " + e.getMessage());
            System.out.println("   Тело ответа: " + e.getResponseBodyAsString());

        } catch (RestClientException e) {
            System.out.println("❌ Ошибка REST клиента: " + e.getMessage());

        } catch (Exception e) {
            System.out.println("❌ Неожиданная ошибка: " + e.getClass().getSimpleName());
            System.out.println("   Сообщение: " + e.getMessage());
        }
    }

    private static void testWithTimeouts() {
        System.out.println("\n📡 Тест 3: Тест с кастомными таймаутами");
        System.out.println("----------------------------------");

        try {
            // Создаем RestTemplate с кастомными таймаутами
            RestTemplate customRestTemplate = new RestTemplate();

            // Используем простой подход без RequestConfig
            long startTime = System.currentTimeMillis();

            try {
                String playersUrl = BASE_URL + "/api/external-players";
                ResponseEntity<String> response = customRestTemplate.getForEntity(playersUrl, String.class);

                long endTime = System.currentTimeMillis();
                System.out.println("✅ Запрос выполнен за " + (endTime - startTime) + " мс");
                System.out.println("   Статус: " + response.getStatusCode());

            } catch (Exception e) {
                long endTime = System.currentTimeMillis();
                System.out.println("❌ Ошибка через " + (endTime - startTime) + " мс");
                System.out.println("   Тип ошибки: " + e.getClass().getSimpleName());
                throw e; // Пробрасываем для обработки в catch
            }

        } catch (ResourceAccessException e) {
            System.out.println("❌ Таймаут подключения: " + e.getMessage());
        } catch (Exception e) {
            System.out.println("❌ Ошибка: " + e.getClass().getSimpleName());
        }
    }
}
