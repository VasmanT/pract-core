//package com.example.practice.repository;
//
//import com.example.practice.model.Player;
//import org.junit.jupiter.api.BeforeEach;
//import org.junit.jupiter.api.Test;
//import org.junit.jupiter.api.DisplayName;
//import org.springframework.beans.factory.annotation.Autowired;
//import org.springframework.boot.test.autoconfigure.orm.jpa.DataJpaTest;
//import org.springframework.boot.test.autoconfigure.orm.jpa.TestEntityManager;
//import org.springframework.test.context.ActiveProfiles;
//
//import java.time.LocalDate;
//import java.util.List;
//import java.util.Optional;
//
//import static org.assertj.core.api.Assertions.assertThat;
//import static org.junit.jupiter.api.Assertions.*;
//
//@DataJpaTest
//@ActiveProfiles("test")  // Используем тестовый профиль
//class PlayerRepositoryTest {
//
//    @Autowired
//    private TestEntityManager entityManager;
//
//    @Autowired
//    private PlayerRepository playerRepository;
//
//    private Player testPlayer;
//
//    @BeforeEach
//    void setUp() {
//        // Создаем тестового игрока перед каждым тестом
//        testPlayer = new Player();
//        testPlayer.setFirstName("Тест");
//        testPlayer.setLastName("Игрок");
//        testPlayer.setPatronymic("Тестович");
//        testPlayer.setGender("man");
//        testPlayer.setGameNumber((byte) 99);
//        testPlayer.setBirthDay(LocalDate.of(2000, 1, 1));
//        testPlayer.setCityPlayer("Тест-Сити");
//
//        entityManager.persist(testPlayer);
//        entityManager.flush();
//    }
//
//    @Test
//    @DisplayName("Тест сохранения игрока")
//    void testSavePlayer() {
//        // Arrange
//        Player newPlayer = new Player();
//        newPlayer.setFirstName("Новый");
//        newPlayer.setLastName("Игрок");
//        newPlayer.setGender("man");
//        newPlayer.setGameNumber((byte) 1);
//        newPlayer.setBirthDay(LocalDate.of(1995, 5, 5));
//        newPlayer.setCityPlayer("Город");
//
//        // Act
//        Player savedPlayer = playerRepository.save(newPlayer);
//
//        // Assert
//        assertNotNull(savedPlayer.getId(), "Сохраненный игрок должен иметь ID");
//        assertThat(savedPlayer.getFirstName()).isEqualTo("Новый");
//        assertThat(savedPlayer.getLastName()).isEqualTo("Игрок");
//    }
//
//    @Test
//    @DisplayName("Тест поиска игрока по ID")
//    void testFindById() {
//        // Act
//        Optional<Player> foundPlayer = playerRepository.findById(testPlayer.getId());
//
//        // Assert
//        assertTrue(foundPlayer.isPresent(), "Игрок должен быть найден");
//        assertEquals(testPlayer.getId(), foundPlayer.get().getId());
//        assertEquals("Тест", foundPlayer.get().getFirstName());
//    }
//
//    @Test
//    @DisplayName("Тест поиска несуществующего игрока")
//    void testFindById_NotFound() {
//        // Act
//        Optional<Player> foundPlayer = playerRepository.findById(999L);
//
//        // Assert
//        assertFalse(foundPlayer.isPresent(), "Несуществующий игрок не должен быть найден");
//    }
//
//    @Test
//    @DisplayName("Тест получения всех игроков")
//    void testFindAll() {
//        // Arrange - добавляем еще одного игрока
//        Player anotherPlayer = new Player();
//        anotherPlayer.setFirstName("Второй");
//        anotherPlayer.setLastName("Игрок");
//        anotherPlayer.setGender("man");
//        anotherPlayer.setGameNumber((byte) 2);
//        anotherPlayer.setBirthDay(LocalDate.of(1996, 6, 6));
//        anotherPlayer.setCityPlayer("Другой город");
//        entityManager.persist(anotherPlayer);
//        entityManager.flush();
//
//        // Act
//        List<Player> players = playerRepository.findAll();
//
//        // Assert
//        assertThat(players).hasSize(2);
//        assertThat(players).extracting(Player::getFirstName)
//                .containsExactlyInAnyOrder("Тест", "Второй");
//    }
//
//    @Test
//    @DisplayName("Тест удаления игрока")
//    void testDelete() {
//        // Arrange
//        Long playerId = testPlayer.getId();
//
//        // Act
//        playerRepository.deleteById(playerId);
//
//        // Assert
//        Optional<Player> deletedPlayer = playerRepository.findById(playerId);
//        assertFalse(deletedPlayer.isPresent(), "Удаленный игрок не должен быть найден");
//    }
//
//    @Test
//    @DisplayName("Тест метода getData из репозитория")
//    void testGetData() {
//        // Act
//        String data = playerRepository.getData();
//
//        // Assert
//        assertNotNull(data);
//        assertTrue(data.contains("крутые данные"));
//        assertTrue(data.contains("Количество игроков в базе: 1."));
//    }
//}