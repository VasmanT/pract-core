package com.example.dbmicro.service;

import com.example.dbmicro.model.Player;
import com.example.dbmicro.repository.PlayerRepository;
import jakarta.persistence.EntityNotFoundException;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.stereotype.Service;

import java.util.List;


public abstract class PlayerServiceImpl implements PlayerService {

    private final PlayerRepository repository;

    public PlayerServiceImpl(PlayerRepository repository) {
        this.repository = repository;
    }

    public String getData() {
        return repository.getData();
    }

    public Player updateById(Player entity) {
        if (entity == null || entity.getId() == null) {
            throw new EntityNotFoundException("Передаваемые параметры не должны быть нулевыми");
        }
        if (!repository.existsById(entity.getId())) {
            throw new EntityNotFoundException("Игрок с id " + entity.getId() + " not found");
        }
        return repository.save(entity);
    }

    public Player getById(Long id) {
        return repository
                .findById(id)
                .orElseThrow(() -> new EntityNotFoundException("Player with ID " + id + " not found"));
    }

    public List<Player> getAll() {
        return repository.findAll();
    }

    public void deleteByID(Long id) {
        if (id == null) {
            throw new EntityNotFoundException("Передаваемые параметры не должны быть нулевыми");
        }
        if (!repository.existsById(id)) {
            throw new EntityNotFoundException("Игрок с id " + id + " not found");
        }
        repository.deleteById(id);
    }

    public Player addNew(Player entity) {
        if (entity == null) {
            throw new EntityNotFoundException("Передаваемые параметры не должны быть нулевыми");
        }

        // Убедитесь, что ID null для новой сущности -- вот тут непонятно
        entity.setId(null);
        //        ----

        return repository.save(entity);
    }
}
