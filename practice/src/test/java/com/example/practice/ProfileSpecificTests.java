//package com.example.practice;
//
//import com.example.practice.service.PlayerService;
//import org.junit.jupiter.api.Disabled;
//import org.junit.jupiter.api.Test;
//import org.springframework.beans.factory.annotation.Autowired;
//import org.springframework.boot.test.context.SpringBootTest;
//import org.springframework.context.annotation.Profile;
//import org.springframework.test.context.ActiveProfiles;
//
//import java.net.HttpURLConnection;
//import java.net.URL;
//
//import static org.junit.jupiter.api.Assertions.*;
//
//@SpringBootTest
//class ProfileSpecificTests {
//
//    @Disabled("Временно отключено до настройки профилей")
//    @Test
////    @ActiveProfiles("dev")
//    @Profile("dev")
//    void testDevProfile() {
//        // Тест для dev профиля
//        // Проверяем, что dev-специфичные бины загружаются
//        System.out.println("Running test with dev profile");
//    }
//
//    @Disabled("Временно отключено до настройки профилей")
//    @Test
//    @Profile("prod")
////    @ActiveProfiles("prod")
//    void testProdProfile() {
//        // Тест для prod профиля
//        System.out.println("Running test with prod profile");
//    }
//
//    @Disabled("Временно отключено до настройки профилей")
//    @Test
//    @Profile("test")
////    @ActiveProfiles("test")
//    void testTestProfile() {
//        // Тест для test профиля
//        System.out.println("Running test with test profile");
//    }
//}
//
//// Тест для проверки профильных сервисов
//@SpringBootTest
////@ActiveProfiles("dev")
//@Profile("dev")
//class DevProfileServiceTest {
//
//    @Autowired
//    private PlayerService playerService;
//
//    @Disabled("Временно отключено до настройки профилей")
//    @Test
//    void testDevServiceImplementation() {
//        String data = playerService.getData();
//        assertNotNull(data);
//        assertTrue(data.contains("[DEV MODE]"));
//        assertTrue(data.contains("(Debug logging enabled)"));
//    }
//}
//
//@SpringBootTest
//@ActiveProfiles("prod")
//class ProdProfileServiceTest {
//    @Autowired
//    private PlayerService playerService;
//
//    @Disabled("Временно отключено до настройки профилей")
//    @Test
//    void testProdServiceImplementation() {
//        String data = playerService.getData();
//        assertNotNull(data);
//        assertTrue(data.contains("[PRODUCTION]"));
//        assertTrue(data.contains("(Optimized for performance)"));
//    }
//}
//
