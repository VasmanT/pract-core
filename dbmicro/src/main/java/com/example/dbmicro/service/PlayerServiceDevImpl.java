package com.example.dbmicro.service;

import com.example.dbmicro.repository.PlayerRepository;
import org.springframework.context.annotation.Profile;
import org.springframework.stereotype.Service;

@Service("playerService")
//@Profile("dev")
public class PlayerServiceDevImpl extends PlayerServiceImpl {
//public class PlayerServiceDevImpl extends PlayerServiceImpl implements PlayerService {

    public PlayerServiceDevImpl(PlayerRepository repository) {
        super(repository);
    }

    @Override
    public String getData() {
        String original = super.getData();
        return "[DEV MODE] " + original + " (Debug logging enabled)";
    }
}