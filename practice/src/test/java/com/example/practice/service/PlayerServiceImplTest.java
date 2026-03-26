//package com.example.practice.service;
//
//import com.example.practice.model.Player;
//import com.example.practice.repository.PlayerRepository;
//import jakarta.persistence.EntityNotFoundException;
//import org.junit.jupiter.api.BeforeEach;
//import org.junit.jupiter.api.Test;
//import org.junit.jupiter.api.DisplayName;
//import org.junit.jupiter.api.extension.ExtendWith;
//import org.mockito.InjectMocks;
//import org.mockito.Mock;
//import org.mockito.junit.jupiter.MockitoExtension;
//
//import java.time.LocalDate;
//import java.util.Arrays;
//import java.util.List;
//import java.util.Optional;
//
//import static org.junit.jupiter.api.Assertions.*;
//import static org.mockito.ArgumentMatchers.any;
//import static org.mockito.ArgumentMatchers.anyLong;
//import static org.mockito.Mockito.*;
//
//@ExtendWith(MockitoExtension.class)  // Подключаем Mockito
//class PlayerServiceImplTest {
//
//    @Mock
//    private PlayerRepository playerRepository;
//
//    @InjectMocks
//    private PlayerServiceImpl playerService;
//
//    private Player testPlayer;
//
//    @BeforeEach
//    void setUp() {
//        // Создаем тестового игрока
//        testPlayer = new Player(
//                1L,
//                "Иван",
//                "Иванов",
//                "Иванович",
//                "man",
//                (byte) 10,
//                LocalDate.of(1990, 1, 1),
//                "Москва"
//        );
//    }
//
//    @Test
//    @DisplayName("Тест получения данных - успешный сценарий")
//    void testGetData_Success() {
//        // Arrange
//        String expectedData = "Тестовые данные";
//        when(playerRepository.getData()).thenReturn(expectedData);
//
//        // Act
//        String result = playerService.getData();
//
//        // Assert
//        assertEquals(expectedData, result);
//        verify(playerRepository, times(1)).getData();
//    }
//
//    @Test
//    @DisplayName("Тест получения игрока по ID - успешный сценарий")
//    void testGetById_Success() {
//        // Arrange
//        when(playerRepository.findById(1L)).thenReturn(Optional.of(testPlayer));
//
//        // Act
//        Player result = playerService.getById(1L);
//
//        // Assert
//        assertNotNull(result);
//        assertEquals(1L, result.getId());
//        assertEquals("Иван", result.getFirstName());
//        verify(playerRepository, times(1)).findById(1L);
//    }
//
//    @Test
//    @DisplayName("Тест получения игрока по ID - игрок не найден")
//    void testGetById_NotFound() {
//        // Arrange
//        when(playerRepository.findById(999L)).thenReturn(Optional.empty());
//
//        // Act & Assert
//        EntityNotFoundException exception = assertThrows(
//                EntityNotFoundException.class,
//                () -> playerService.getById(999L)
//        );
//
//        assertEquals("Player with ID 999 not found", exception.getMessage());
//        verify(playerRepository, times(1)).findById(999L);
//    }
//
//    @Test
//    @DisplayName("Тест получения всех игроков")
//    void testGetAll() {
//        // Arrange
//        Player player2 = new Player(
//                2L,
//                "Петр",
//                "Петров",
//                "Петрович",
//                "man",
//                (byte) 11,
//                LocalDate.of(1991, 2, 2),
//                "Санкт-Петербург"
//        );
//
//        List<Player> players = Arrays.asList(testPlayer, player2);
//        when(playerRepository.findAll()).thenReturn(players);
//
//        // Act
//        List<Player> result = playerService.getAll();
//
//        // Assert
//        assertEquals(2, result.size());
//        assertEquals("Иван", result.get(0).getFirstName());
//        assertEquals("Петр", result.get(1).getFirstName());
//        verify(playerRepository, times(1)).findAll();
//    }
//
//    @Test
//    @DisplayName("Тест создания нового игрока - успешный сценарий")
//    void testAddNew_Success() {
//        // Arrange
//        Player newPlayer = new Player(
//                null,  // ID должен быть null для новой сущности
//                "Новый",
//                "Игрок",
//                null,
//                "man",
//                (byte) 99,
//                LocalDate.of(2000, 1, 1),
//                "Город"
//        );
//
//        Player savedPlayer = new Player(
//                3L,  // После сохранения получаем ID
//                "Новый",
//                "Игрок",
//                null,
//                "man",
//                (byte) 99,
//                LocalDate.of(2000, 1, 1),
//                "Город"
//        );
//
//        when(playerRepository.save(any(Player.class))).thenReturn(savedPlayer);
//
//        // Act
//        Player result = playerService.addNew(newPlayer);
//
//        // Assert
//        assertNotNull(result);
//        assertEquals(3L, result.getId());
//        assertEquals("Новый", result.getFirstName());
//        assertNull(newPlayer.getId(), "ID должен быть null перед сохранением");
//        verify(playerRepository, times(1)).save(newPlayer);
//    }
//
//    @Test
//    @DisplayName("Тест создания нового игрока - передача null")
//    void testAddNew_NullEntity() {
//        // Act & Assert
//        EntityNotFoundException exception = assertThrows(
//                EntityNotFoundException.class,
//                () -> playerService.addNew(null)
//        );
//
//        assertEquals("Передаваемые параметры не должны быть нулевыми", exception.getMessage());
//        verify(playerRepository, never()).save(any());
//    }
//
//    @Test
//    @DisplayName("Тест обновления игрока - успешный сценарий")
//    void testUpdateById_Success() {
//        // Arrange
//        Player updatedPlayer = new Player(
//                1L,
//                "Обновленный",
//                "Игрок",
//                "Тестович",
//                "man",
//                (byte) 99,
//                LocalDate.of(2000, 1, 1),
//                "Обновленный город"
//        );
//
//        when(playerRepository.existsById(1L)).thenReturn(true);
//        when(playerRepository.save(any(Player.class))).thenReturn(updatedPlayer);
//
//        // Act
//        Player result = playerService.updateById(updatedPlayer);
//
//        // Assert
//        assertEquals("Обновленный", result.getFirstName());
//        assertEquals("Обновленный город", result.getCityPlayer());
//        verify(playerRepository, times(1)).existsById(1L);
//        verify(playerRepository, times(1)).save(updatedPlayer);
//    }
//
//    @Test
//    @DisplayName("Тест обновления игрока - игрок не найден")
//    void testUpdateById_NotFound() {
//        // Arrange
//        when(playerRepository.existsById(999L)).thenReturn(false);
//
//        // Act & Assert
//        EntityNotFoundException exception = assertThrows(
//                EntityNotFoundException.class,
//                () -> playerService.updateById(new Player(999L, "Имя", "Фамилия", null, "man", (byte) 1, LocalDate.now(), "Город"))
//        );
//
//        assertEquals("Игрок с id 999 not found", exception.getMessage());
//        verify(playerRepository, times(1)).existsById(999L);
//        verify(playerRepository, never()).save(any());
//    }
//
//    @Test
//    @DisplayName("Тест удаления игрока - успешный сценарий")
//    void testDeleteByID_Success() {
//        // Arrange
//        when(playerRepository.existsById(1L)).thenReturn(true);
//        doNothing().when(playerRepository).deleteById(1L);
//
//        // Act
//        playerService.deleteByID(1L);
//
//        // Assert - проверяем, что метод был вызван без ошибок
//        verify(playerRepository, times(1)).existsById(1L);
//        verify(playerRepository, times(1)).deleteById(1L);
//    }
//
//    @Test
//    @DisplayName("Тест удаления игрока - игрок не найден")
//    void testDeleteByID_NotFound() {
//        // Arrange
//        when(playerRepository.existsById(999L)).thenReturn(false);
//
//        // Act & Assert
//        EntityNotFoundException exception = assertThrows(
//                EntityNotFoundException.class,
//                () -> playerService.deleteByID(999L)
//        );
//
//        assertEquals("Игрок с id 999 not found", exception.getMessage());
//        verify(playerRepository, times(1)).existsById(999L);
//        verify(playerRepository, never()).deleteById(anyLong());
//    }
//
//    @Test
//    @DisplayName("Тест удаления игрока - передача null")
//    void testDeleteByID_NullId() {
//        // Act & Assert
//        EntityNotFoundException exception = assertThrows(
//                EntityNotFoundException.class,
//                () -> playerService.deleteByID(null)
//        );
//
//        assertEquals("Передаваемые параметры не должны быть нулевыми", exception.getMessage());
//        verify(playerRepository, never()).existsById(anyLong());
//        verify(playerRepository, never()).deleteById(anyLong());
//    }
//}