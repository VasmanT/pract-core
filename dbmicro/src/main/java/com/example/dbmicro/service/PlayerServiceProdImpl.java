package com.example.dbmicro.service;

import com.example.dbmicro.repository.PlayerRepository;
import org.springframework.context.annotation.Profile;
import org.springframework.stereotype.Service;

@Service("PlayerServiceProdImpl")
public class PlayerServiceProdImpl extends PlayerServiceImpl{

    public PlayerServiceProdImpl(PlayerRepository repository) {
        super(repository);
    }

    @Override
    public String getData() {
        String original = super.getData();
        return "[PRODUCTION] " + original + " (Optimized for performance)";
    }
}