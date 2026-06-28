package com.example.kafkamicro.dto;

import com.example.kafkamicro.model.Player;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;
import java.util.UUID;

/**
 * DTO команды - должно быть идентично тому, что отправляет practice
 * Kafka не знает типы, поэтому мы должны использовать те же имена полей
 */

@Data
@NoArgsConstructor
@AllArgsConstructor
public class PlayerCommand {

    public enum CommandType {
        CREATE, UPDATE, DELETE
    }

    private CommandType command;      // CREATE, UPDATE, DELETE
    private Long playerId;            // для UPDATE/DELETE
    private Player player;            // для CREATE/UPDATE (может быть null для DELETE)
    private String requestId;         // уникальный ID запроса для трассировки
    private LocalDateTime timestamp;  // когда команда создана

    // Удобный конструктор для CREATE
    public static PlayerCommand create(Player player) {
        return new PlayerCommand(
                CommandType.CREATE,
                null,
                player,
                UUID.randomUUID().toString(),
                LocalDateTime.now()
        );
    }

    // Удобный конструктор для UPDATE
    public static PlayerCommand update(Long id, Player player) {
        return new PlayerCommand(
                CommandType.UPDATE,
                id,
                player,
                UUID.randomUUID().toString(),
                LocalDateTime.now()
        );
    }

    // Удобный конструктор для DELETE
    public static PlayerCommand delete(Long id) {
        return new PlayerCommand(
                CommandType.DELETE,
                id,
                null,
                UUID.randomUUID().toString(),
                LocalDateTime.now()
        );
    }
}