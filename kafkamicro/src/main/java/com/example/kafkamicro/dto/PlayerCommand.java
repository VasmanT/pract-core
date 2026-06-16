package com.example.kafkamicro.dto;

import com.example.kafkamicro.model.Player;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

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
    private String requestId;         // для трассировки
    private LocalDateTime timestamp;  // когда команда создана
}