package com.example.kafkamicro.dto;

import lombok.Builder;
import lombok.Data;
import java.time.LocalDateTime;
import java.util.List;

@Data
@Builder
public class MessageResponse {
    private List<String> messages;
    private int count;
    private LocalDateTime timestamp;
    private String topic;
}