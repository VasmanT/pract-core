package com.example.dbmicro.controller;

import com.example.dbmicro.service.PlayerService;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/info")
public class ProfileInfoController {

//    @Value("${spring.profiles.active}")
//    private String activeProfile = "no Profile";


    @Value("${spring.profiles.active}")
    private String activeProfile;

    public final PlayerService playerService;

//    public ProfileInfoController(@Qualifier("PlayerServiceProdImpl") PlayerService playerService) {
    public ProfileInfoController(PlayerService playerService) {
        this.playerService = playerService;
    }


    @GetMapping("/profile")
    public String getActiveProfile() {
        return "Active profile: " + activeProfile;
    }


    @GetMapping("/env")
    public String getEnvInfo() {
        if (activeProfile.equals("dev")) {
            return "Development environment - Debug mode enabled " + playerService.getData();
        } else if (activeProfile.equals("prod")) {
            return "Production environment - Performance optimized " + playerService.getData();
        }
        return "Unknown environment";
    }
//
//    @GetMapping("/env")
//    @Profile("dev")
//    public String getDevInfo() {
//        String result = playerService.getData();
//        return "Development environment - Debug m0de enabled " + result;
//    }
//
//    @PostMapping("/env")
//    @Profile("prod")
//    public String getProdInfo() {
//        String result = playerService.getData();
//        return "Production environment - Performance optimized " + result;
//    }
}