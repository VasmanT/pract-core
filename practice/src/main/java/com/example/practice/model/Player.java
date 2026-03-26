package com.example.practice.model;

import io.swagger.v3.oas.annotations.media.Schema;

import java.time.LocalDate;


public record Player(
        @Schema(description = "Уникальный идентификатор игрока", example = "1")
        Long id,

        @Schema(description = "Имя игрока", example = "Максим")
        String firstName,

//    @Column(name = "last_name")
        @Schema(description = "Фамилия игрока", example = "Максимов")
        String lastName,

        @Schema(description = "Отчество игрока", example = "Максимович")
        String patronymic,

        @Schema(description = "Пол игрока", example = "man")
        String gender,

        @Schema(description = "Игровой номер игрока", example = "11")
        byte gameNumber,

        @Schema(description = "Дата рождения игрока", example = "2022, 1, 27")
        LocalDate birthDay,

        @Schema(description = "Город проживания игрока", example = "Кострома")
        String cityPlayer
) {
}
