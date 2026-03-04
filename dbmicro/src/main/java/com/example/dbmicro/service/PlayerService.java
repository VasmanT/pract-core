package com.example.dbmicro.service;

import com.example.dbmicro.model.Player;

import java.util.List;

public interface PlayerService {

    public String getData();
    public List<Player> getAll();
    public void deleteByID(Long id);
    public Player addNew(Player entity);
    public Player updateById(Player entity);
    public Player getById(Long id);


}
