package com.example.dbmicro.model;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import java.time.LocalDate;

@Entity
@Table(name = "players")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Schema(description = "Сущность игрока")
public class Player {

        @Id
        @GeneratedValue(strategy = GenerationType.IDENTITY)
        @Schema(description = "Уникальный идентификатор игрока", example = "1")
        private Long id;

        @Column(name = "first_name")
        @Schema(description = "Имя игрока", example = "Максим")
        private String firstName;

        @Column(name = "last_name")
        @Schema(description = "Фамилия игрока", example = "Максимов")
        private String lastName;

        @Column(name = "patronymic")
        @Schema(description = "Отчество игрока", example = "Максимович")
        private String patronymic;

        @Column(name = "gender")
        @Schema(description = "Пол игрока", example = "man")
        private String gender;

        @Column(name = "game_number")
        @Schema(description = "Игровой номер игрока", example = "11")
        private byte gameNumber;

        @Column(name = "birth_day")
        @Schema(description = "Дата рождения игрока", example = "2022-01-27")
        private LocalDate birthDay;

        @Column(name = "city_player")
        @Schema(description = "Город проживания игрока", example = "Кострома")
        private String cityPlayer;
}