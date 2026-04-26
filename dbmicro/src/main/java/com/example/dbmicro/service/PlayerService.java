package com.example.dbmicro.service;

import com.example.dbmicro.model.Player;

import java.util.List;

public interface PlayerService {

    String getData();
    List<Player> getAll();
    void deleteByID(Long id);
    Player addNew(Player entity);
    Player updateById(Player entity);
    Player getById(Long id);


}
