//package com.example.practice.controller;
//
//import com.example.practice.model.Player;
////import com.example.practice.repository.PlayerRepository;
//import org.junit.jupiter.api.BeforeEach;
//import org.junit.jupiter.api.Test;
//import org.junit.jupiter.api.DisplayName;
//import org.springframework.beans.factory.annotation.Autowired;
//import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
//import org.springframework.boot.test.context.SpringBootTest;
//import org.springframework.http.MediaType;
//import org.springframework.test.context.ActiveProfiles;
//import org.springframework.test.context.TestPropertySource;
//import org.springframework.test.web.servlet.MockMvc;
//import org.springframework.transaction.annotation.Transactional;
//
//import java.time.LocalDate;
//
//import static org.hamcrest.Matchers.*;
//import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
//import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;
//
//@SpringBootTest
//@AutoConfigureMockMvc
//@ActiveProfiles("test")
//@TestPropertySource(locations = "classpath:application-test.properties")
//@Transactional  // Каждый тест выполняется в транзакции и откатывается после завершения
//class PlayerControllerIntegrationTest {
//
//    @Autowired
//    private MockMvc mockMvc;
//
//    @Autowired
////    private PlayerRepository playerRepository;
//
//    private Player savedPlayer;
//
//    @BeforeEach
//    void setUp() {
//        // Очищаем базу перед каждым тестом
////        playerRepository.deleteAll();
//
//        // Создаем тестового игрока
//        Player player = new Player(
//                null,
//                "Интеграционный",
//                "Тест",
//                "Тестович",
//                "man",
//                (byte) 99,
//                LocalDate.of(2000, 1, 1),
//                "Тест-Сити"
//        );
//
////        savedPlayer = playerRepository.save(player);
//    }
//
//    @Test
//    @DisplayName("Интеграционный тест: создание и получение игрока")
//    void testCreateAndGetPlayer() throws Exception {
//        // Act & Assert - проверяем, что игрок создан
//        mockMvc.perform(get("/api/players/{id}", savedPlayer.getId()))
//                .andExpect(status().isOk())
//                .andExpect(jsonPath("$.firstName", is("Интеграционный")))
//                .andExpect(jsonPath("$.lastName", is("Тест")))
//                .andExpect(jsonPath("$.cityPlayer", is("Тест-Сити")));
//    }
//
//    @Test
//    @DisplayName("Интеграционный тест: полный цикл CRUD операций")
//    void testFullCrudCycle() throws Exception {
//        // 1. Создаем нового игрока
//        String newPlayerJson = """
//            {
//                "firstName": "Новый",
//                "lastName": "Игрок",
//                "gender": "man",
//                "gameNumber": 1,
//                "birthDay": "1995-05-05",
//                "cityPlayer": "Город"
//            }
//            """;
//
//        // 2. Получаем всех игроков (должен быть 1)
//        mockMvc.perform(get("/api/players"))
//                .andExpect(status().isOk())
//                .andExpect(jsonPath("$", hasSize(1)));
//
//        // 3. Обновляем существующего игрока
//        String updatedPlayerJson = """
//            {
//                "id": %d,
//                "firstName": "Обновленный",
//                "lastName": "Игрок",
//                "gender": "man",
//                "gameNumber": 99,
//                "birthDay": "2000-01-01",
//                "cityPlayer": "Обновленный Город"
//            }
//            """.formatted(savedPlayer.getId());
//
//        mockMvc.perform(put("/api/players/{id}", savedPlayer.getId())
//                        .contentType(MediaType.APPLICATION_JSON)
//                        .content(updatedPlayerJson))
//                .andExpect(status().isOk())
//                .andExpect(jsonPath("$.firstName", is("Обновленный")))
//                .andExpect(jsonPath("$.cityPlayer", is("Обновленный Город")));
//
//        // 4. Удаляем игрока
//        mockMvc.perform(delete("/api/players/{id}", savedPlayer.getId()))
//                .andExpect(status().isNoContent());
//
//        // 5. Проверяем, что игрок удален
//        mockMvc.perform(get("/api/players"))
//                .andExpect(status().isOk())
//                .andExpect(jsonPath("$", hasSize(0)));
//    }
//
//    @Test
//    @DisplayName("Интеграционный тест: проверка валидации")
//    void testValidation() throws Exception {
//        // Попытка создать игрока с недостаточными данными
//        String invalidPlayerJson = """
//            {
//                "firstName": "",
//                "lastName": "",
//                "gender": "invalid"
//            }
//            """;
//
//        // В реальном приложении здесь будет проверка валидации
//        // Для текущей реализации просто проверяем, что запрос проходит
//        // (в будущем можно добавить валидацию и тесты для нее)
//        mockMvc.perform(post("/api/players")
//                        .contentType(MediaType.APPLICATION_JSON)
//                        .content(invalidPlayerJson))
//                .andExpect(status().isCreated()); // или .isBadRequest() если добавить валидацию
//    }
//}