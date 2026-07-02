package com.example.dbmicro.controller;

import com.example.dbmicro.model.Player;
import com.example.dbmicro.service.PlayerService;
import com.example.dbmicro.service.PlayerServiceProdImpl;
import io.swagger.v3.oas.annotations.Operation;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

import static org.springframework.http.HttpStatus.CREATED;
import static org.springframework.http.ResponseEntity.noContent;
import static org.springframework.http.ResponseEntity.ok;

@RestController
@RequestMapping({"/api/players", "/api/players/"})
public class PlayerController {

    public final PlayerService playerService;

    public PlayerController(PlayerService playerService) {
        this.playerService = playerService;
    }

    @Operation(summary = "Проверка того, что приложение обновилось")
    @GetMapping("/getdata")
    public ResponseEntity<String> getData() {
        return ok(playerService.getData());
    }

    @Operation(summary = "Получить игрока по ID")
    @GetMapping("/{id}")
    public ResponseEntity<Player> getById(@PathVariable("id") Long id) {
        return ok(playerService.getById(id));
    }

    @Operation(summary = "Получить всех игроков")
    @GetMapping
    public ResponseEntity<List<Player>> getAll() {
        return ok(playerService.getAll());
    }

    @Operation(summary = "Создать нового игрока")
    @PostMapping
    public ResponseEntity<Player> create(@RequestBody Player dto) {
        return new ResponseEntity<>(playerService.addNew(dto), CREATED);
    }

    @Operation(summary = "Обновить данные игрока")
    @PutMapping("/{id}")
    public ResponseEntity<Player> update(@PathVariable Long id, @RequestBody Player entity) {
        if (!entity.getId().equals(id)) {
            throw new IllegalArgumentException("ID в пути и теле запроса не совпадают");
        }
        return ok(playerService.updateById(entity));
    }

    @Operation(summary = "Удалить игрока по id")
    @DeleteMapping("/{id}")
    public ResponseEntity<Void> delete(@PathVariable Long id) {
        playerService.deleteByID(id);
        return noContent().build();
    }

    @Operation(summary = "Удалить всех игроков")
    @DeleteMapping
    public ResponseEntity<Void> deleteAll() {
        playerService.deleteAll();
        return noContent().build();
    }
}
