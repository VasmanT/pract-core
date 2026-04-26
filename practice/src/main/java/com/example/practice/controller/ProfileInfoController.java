package com.example.practice.controller;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/info")
public class ProfileInfoController {

//    @Value("${spring.profiles.active}")
    @Value("${spring.profiles.active}")
    private String activeProfile;

    @GetMapping("/profile")
    public String getActiveProfile() {
        return "крутые данные, - practice 2604_dc2. Active profile: " + activeProfile;
    }

    @GetMapping("/env")
    public String getEnvInfo() {
        if (activeProfile.equals("dev")) {
            return "Development environment - Debug mode enabled ";
        } else if (activeProfile.equals("prod")) {
            return "Production environment - Performance optimized ";
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