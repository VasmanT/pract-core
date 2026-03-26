//package com.example.practice.model;
//
//import org.junit.jupiter.api.Test;
//import org.junit.jupiter.api.DisplayName;
//
//import java.time.LocalDate;
//
//import static org.junit.jupiter.api.Assertions.*;
//
//class PlayerTest {
//
//    @Test
//    @DisplayName("Тест создания игрока с валидными данными")
//    void testPlayerCreation() {
//        // Arrange (Подготовка данных)
//        Player player = new Player();
//        player.setId(1L);
//        player.setFirstName("Иван");
//        player.setLastName("Иванов");
//        player.setPatronymic("Иванович");
//        player.setGender("man");
//        player.setGameNumber((byte) 10);
//        player.setBirthDay(LocalDate.of(1990, 1, 1));
//        player.setCityPlayer("Москва");
//
//        // Act (Выполнение действия) - в данном случае просто создание объекта
//
//        // Assert (Проверка результатов)
//        assertAll(
//                () -> assertEquals(1L, player.getId()),
//                () -> assertEquals("Иван", player.getFirstName()),
//                () -> assertEquals("Иванов", player.getLastName()),
//                () -> assertEquals("Иванович", player.getPatronymic()),
//                () -> assertEquals("man", player.getGender()),
//                () -> assertEquals((byte) 10, player.getGameNumber()),
//                () -> assertEquals(LocalDate.of(1990, 1, 1), player.getBirthDay()),
//                () -> assertEquals("Москва", player.getCityPlayer())
//        );
//    }
//
//    @Test
//    @DisplayName("Тест equals и hashCode методов")
//    void testEqualsAndHashCode() {
//        // Arrange
//        Player player1 = new Player(1L, "Иван", "Иванов", "Иванович",
//                "man", (byte) 10, LocalDate.of(1990, 1, 1), "Москва");
//        Player player2 = new Player(1L, "Иван", "Иванов", "Иванович",
//                "man", (byte) 10, LocalDate.of(1990, 1, 1), "Москва");
//        Player player3 = new Player(2L, "Петр", "Петров", "Петрович",
//                "man", (byte) 11, LocalDate.of(1991, 2, 2), "Санкт-Петербург");
//
//        // Act & Assert
////        assertEquals(player1, player2, "Игроки с одинаковыми ID должны быть равны");
//        assertNotEquals(player1, player3, "Игроки с разными ID не должны быть равны");
////        assertEquals(player1.hashCode(), player2.hashCode(), "Хеш-коды равных объектов должны совпадать");
//    }
//}