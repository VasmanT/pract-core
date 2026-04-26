package com.example.dbmicro.service;

import com.example.dbmicro.repository.PlayerRepository;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.context.annotation.Profile;
import org.springframework.stereotype.Service;

@Service
@Profile("dev")
public class PlayerServiceDevImpl extends PlayerServiceImpl {

    public PlayerServiceDevImpl(PlayerRepository repository) {
        super(repository);
    }

    @Override
    public String getData() {
        String original = super.getData();
        return "[DEV MODE] " + original + " (Debug logging enabled)";
    }
}