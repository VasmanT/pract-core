//package com.example.practice;
//
//import com.example.practice.controller.ApiClientController;
//import com.example.practice.model.Player;
//import org.junit.jupiter.api.Test;
//import org.springframework.beans.factory.annotation.Autowired;
//import org.springframework.boot.test.context.SpringBootTest;
//import org.springframework.boot.test.mock.mockito.MockBean;
//import org.springframework.boot.test.web.client.TestRestTemplate;
//import org.springframework.boot.test.web.server.LocalServerPort;
//import org.springframework.http.ResponseEntity;
//import org.springframework.http.HttpStatus;
//import org.springframework.web.client.RestTemplate;
//
//import java.time.LocalDate;
//import java.util.Arrays;
//
//import static org.assertj.core.api.Assertions.assertThat;
//import static org.junit.jupiter.api.Assertions.*;
//import static org.mockito.ArgumentMatchers.*;
//import static org.mockito.Mockito.*;
//
///**
// * Интеграционный тест с изоляцией - не требует реальной БД!
// * Проверяет только связь между practice и dbmicro
// */
//@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
//public class ApiClientIntegrationTest {
//
//    @LocalServerPort
//    private int port;
//
//    @Autowired
//    private TestRestTemplate restTemplate;
//
//    // Мокаем RestTemplate, чтобы не обращаться к реальному dbmicro
//    @MockBean
//    private RestTemplate mockRestTemplate;
//
//    // Создаем реальный контроллер, но с замоканным RestTemplate
//    @Autowired
//    private ApiClientController apiClientController;
//
//    @Test
//    void testExternalPlayersEndpointReturnsData() {
//        // Подготавливаем тестовые данные
//        Player[] mockPlayers = {
//                createPlayer(1L, "Иван", "Иванов"),
//                createPlayer(2L, "Петр", "Петров")
//        };
//
//        // Настраиваем мок
//        ResponseEntity<Player[]> mockResponse = ResponseEntity.ok(mockPlayers);
//        when(mockRestTemplate.exchange(
//                anyString(),
//                any(),
//                any(),
//                eq(Player[].class)
//        )).thenReturn(mockResponse);
//
//        // Вызываем реальный эндпоинт
//        String url = "http://localhost:" + port + "/api/external-players";
//        ResponseEntity<Player[]> response = restTemplate.getForEntity(url, Player[].class);
//
//        // Проверяем результат
//        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.OK);
//        assertNotNull(response.getBody());
//        assertThat(response.getBody().length).isEqualTo(2);
//
//        System.out.println("✅ Тест успешен! Получено игроков: " + response.getBody().length);
//    }
//
//    @Test
//    void testExternalPlayersEndpointHandlesEmptyResponse() {
//        // Пустой ответ
//        Player[] emptyPlayers = {};
//        ResponseEntity<Player[]> mockResponse = ResponseEntity.ok(emptyPlayers);
//
//        when(mockRestTemplate.exchange(
//                anyString(),
//                any(),
//                any(),
//                eq(Player[].class)
//        )).thenReturn(mockResponse);
//
//        String url = "http://localhost:" + port + "/api/external-players";
//        ResponseEntity<Player[]> response = restTemplate.getForEntity(url, Player[].class);
//
//        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.OK);
//        assertNotNull(response.getBody());
//        assertThat(response.getBody().length).isEqualTo(0);
//
//        System.out.println("✅ Тест с пустым ответом успешен");
//    }
//
//    @Test
//    void testExternalPlayersEndpointHandlesError() {
//        // Эмулируем ошибку
//        when(mockRestTemplate.exchange(
//                anyString(),
//                any(),
//                any(),
//                eq(Player[].class)
//        )).thenThrow(new RuntimeException("Сервис недоступен"));
//
//        String url = "http://localhost:" + port + "/api/external-players";
//        ResponseEntity<String> response = restTemplate.getForEntity(url, String.class);
//
//        // Контроллер должен вернуть SERVICE_UNAVAILABLE
//        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.SERVICE_UNAVAILABLE);
//        assertNotNull(response.getBody());
//        assertTrue(response.getBody().contains("Не удалось получить данные"));
//
//        System.out.println("✅ Тест с ошибкой успешен");
//    }
//
//    @Test
//    void testDirectCallToController() {
//        // Тестируем контроллер напрямую, без HTTP
//        Player[] mockPlayers = {createPlayer(1L, "Тест", "Тестов")};
//        ResponseEntity<Player[]> mockResponse = ResponseEntity.ok(mockPlayers);
//
//        when(mockRestTemplate.exchange(
//                anyString(),
//                any(),
//                any(),
//                eq(Player[].class)
//        )).thenReturn(mockResponse);
//
//        ResponseEntity<?> response = apiClientController.getUsersFromExternalApp();
//
//        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.OK);
//        assertNotNull(response.getBody());
//
//        System.out.println("✅ Прямой вызов контроллера успешен");
//    }
//
//    private Player createPlayer(Long id, String firstName, String lastName) {
//        Player player = new Player();
//        player.setId(id);
//        player.setFirstName(firstName);
//        player.setLastName(lastName);
//        player.setBirthDay(LocalDate.of(1990, 1, 1));
//        player.setGender("MALE");
//        player.setGameNumber((byte) 10);
//        return player;
//    }
//}