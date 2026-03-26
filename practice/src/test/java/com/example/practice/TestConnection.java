package com.example.practice;
//import java.net.HttpURLConnection;
//import java.net.URL;

import java.net.HttpURLConnection;
import java.net.URL;

public class TestConnection {
    public static void main(String[] args) {
        try {
            URL url = new URL("http://localhost:8091/api/players");
            HttpURLConnection conn = (HttpURLConnection) url.openConnection();
            conn.setRequestMethod("GET");
            conn.setConnectTimeout(5000);

            int responseCode = conn.getResponseCode();
            System.out.println("Response Code: " + responseCode);

            if (responseCode == 200) {
                System.out.println("✅ dbmicro доступен!");
            } else {
                System.out.println("❌ dbmicro вернул код: " + responseCode);
            }
        } catch (Exception e) {
            System.out.println("❌ Ошибка подключения к dbmicro: " + e.getMessage());
        }
    }
}
