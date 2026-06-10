package com.example.kafkamicro.dto;

import jakarta.validation.constraints.NotBlank;
import lombok.Data;

@Data
public class MessageRequest {
    @NotBlank(message = "Сообщение не может быть пустым")
    private String message;

    private String key;
}