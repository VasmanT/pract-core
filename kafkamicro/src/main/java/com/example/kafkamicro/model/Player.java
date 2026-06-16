package com.example.kafkamicro.model;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import java.time.LocalDate;

/**
 * Модель игрока - полная копия того, что в dbmicro
 * Почему копия? Потому что kafkamicro не зависит от dbmicro напрямую
 * Это хорошая практика: каждый сервис имеет свою копию DTO
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
public class Player {
    private Long id;
    private String firstName;
    private String lastName;
    private String patronymic;
    private String gender;
    private byte gameNumber;
    private LocalDate birthDay;
    private String cityPlayer;
}