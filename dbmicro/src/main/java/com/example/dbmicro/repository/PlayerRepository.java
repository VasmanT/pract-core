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
        var currentDateTime = now(ZoneId.of("Europe/Moscow"))
                .format(ofPattern("dd.MM.yyyy HH:mm:ss z"));
        return " dbmicro . V1-дубльтест (" + currentDateTime + "). Количество игроков в базе: " + count() + ".";
    }
}