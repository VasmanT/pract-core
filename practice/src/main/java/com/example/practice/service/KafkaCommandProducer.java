package com.example.practice.service;

import com.example.practice.dto.PlayerCommand;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
@Slf4j
public class KafkaCommandProducer {

    private final KafkaTemplate<String, PlayerCommand> kafkaTemplate;

    @Value("${kafka.topics.player-commands:player-commands}")
    private String topic;

    /**
     * Отправить команду в Kafka
     * @return true если отправлено успешно
     */
    public boolean sendCommand(PlayerCommand command) {
        try {
            log.info("Отправка команды {} в топик {}: {}",
                    command.getCommand(), topic, command);

            // Отправляем асинхронно с callback для логирования
            kafkaTemplate.send(topic, command.getCommand().toString(), command)
                    .whenComplete((result, ex) -> {
                        if (ex == null) {
                            log.info("Команда {} отправлена успешно. Partition: {}, Offset: {}",
                                    command.getRequestId(),
                                    result.getRecordMetadata().partition(),
                                    result.getRecordMetadata().offset());
                        } else {
                            log.error("Ошибка при отправке команды {}: {}",
                                    command.getRequestId(), ex.getMessage(), ex);
                        }
                    });

            return true;
        } catch (Exception e) {
            log.error("Не удалось отправить команду в Kafka", e);
            return false;
        }
    }
}