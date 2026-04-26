package com.example.dbmicro.repository;

import com.example.dbmicro.model.Player;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.time.ZoneId;

import static java.time.ZonedDateTime.now;
import static java.time.format.DateTimeFormatter.ofPattern;

@Repository("playerRepository")
public interface PlayerRepository extends JpaRepository<Player, Long> {
    default String getData() {
        // Формат: 03.12.2025 14:30:45
        var currentDateTime = now(ZoneId.of("Europe/Moscow"))
                .format(ofPattern("dd.MM.yyyy HH:mm:ss z"));
        return "крутые данные, - dbmicro 2604_dc2(" + currentDateTime + "). Тест git. Количество игроков в базе: " + count() + ".";
    }
}


/*
@org.springframework.stereotype.Repository("playerRepository")
public interface PlayerRepository extends org.springframework.data.jpa.repository.JpaRepository<com.example.practice.model.Player, java.lang.Long> {
    default java.lang.String getData() {
        // Формат: 03.12.2025 14:30:45
        java.lang.String currentDateTime = java.time.ZonedDateTime.now(java.time.ZoneId.of("Europe/Moscow"))
                .format(java.time.format.DateTimeFormatter.ofPattern("dd.MM.yyyy HH:mm:ss z"));
        return "крутые данные, - version3("+currentDateTime+"). Количество игроков в базе: "+ count()+".";
    }
}*/
