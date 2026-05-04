package com.example.practice.controller;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/info")
public class ProfileInfoController {

    @Value("${spring.profiles.active}")
    private String activeProfile;

    @GetMapping("/profile")
    public String getActiveProfile() {
        return "practice V2. Active profile: " + activeProfile;
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
}