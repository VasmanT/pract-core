package com.example.kafkamicro.service;

import com.example.kafkamicro.dto.PlayerCommand;
import com.example.kafkamicro.model.Player;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.kafka.annotation.KafkaListener;
import org.springframework.kafka.support.Acknowledgment;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;

/**
 * Основной сервис, который обрабатывает команды из Kafka
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class CommandProcessorService {

    private final RestTemplate restTemplate;

    @Value("${dbmicro.api.url:http://host.docker.internal:8096/api/players}")
    private String dbmicroUrl;

    /**
     * Этот метод вызывается автоматически при появлении сообщения в топике
     *
     * @param command        команда из Kafka (автоматически десериализуется из JSON)
     * @param acknowledgment объект для подтверждения обработки
     */
    @KafkaListener(
            topics = "${kafka.topics.player-commands}",  // слушаем этот топик
            containerFactory = "kafkaListenerContainerFactory"  // используем нашу фабрику
    )
    public void processCommand(PlayerCommand command, Acknowledgment acknowledgment) {

        log.info("=== ПОЛУЧЕНА КОМАНДА ===");
        log.info("RequestId: {}", command.getRequestId());
        log.info("Command type: {}", command.getCommand());
        log.info("PlayerId: {}", command.getPlayerId());
        log.info("Timestamp: {}", command.getTimestamp());

        try {
            // В зависимости от типа команды вызываем разные REST методы
            switch (command.getCommand()) {
                case CREATE:
                    handleCreate(command);
                    break;
                case UPDATE:
                    handleUpdate(command);
                    break;
                case DELETE:
                    handleDelete(command);
                    break;
                default:
                    log.warn("Неизвестный тип команды: {}", command.getCommand());
            }

            // ВАЖНО! Если дошли сюда без ошибки - подтверждаем обработку
            // Kafka запомнит, что сообщение обработано, и не отправит его снова
            acknowledgment.acknowledge();
            log.info("Команда {} успешно обработана и подтверждена", command.getRequestId());

        } catch (Exception e) {
            // В случае ошибки НЕ подтверждаем сообщение
            // Kafka отправит его снова (после timeout'а)
            log.error("ОШИБКА при обработке команды {}: {}",
                    command.getRequestId(), e.getMessage(), e);

            // Здесь можно добавить логику:
            // - отправить в Dead Letter Topic
            // - сохранить в БД для ручного разбора
            // - просто залогировать
        }
    }

    /**
     * Обработка CREATE команды
     */
    private void handleCreate(PlayerCommand command) {
        Player player = command.getPlayer();
        log.info("Создание игрока: {} {}", player.getFirstName(), player.getLastName());

        // POST запрос к dbmicro
        String url = dbmicroUrl;
        log.debug("POST {} с телом: {}", url, player);

        Player created = restTemplate.postForObject(url, player, Player.class);

        log.info("Игрок создан с id: {}", created != null ? created.getId() : "unknown");
    }

    /**
     * Обработка UPDATE команды
     */
    private void handleUpdate(PlayerCommand command) {
        Long id = command.getPlayerId();
        Player player = command.getPlayer();

        log.info("Обновление игрока с id={}", id);

        // PUT запрос к dbmicro
        String url = dbmicroUrl + "/" + id;
        log.debug("PUT {}", url);

        // В RestTemplate нет удобного putForObject, используем exchange
        restTemplate.put(url, player);

        log.info("Игрок {} обновлен", id);
    }

    /**
     * Обработка DELETE команды
     */


    private void handleDelete(PlayerCommand command) {
        String url = dbmicroUrl;
        Long id = command.getPlayerId();

        if (id != null) {
            log.info("Удаление игрока с id={}", id);
            url = dbmicroUrl + "/" + id;
        } else {
            log.info("Удаление всех игроков");
        }

        log.debug("DELETE {}", url);
        restTemplate.delete(url);

        if (id != null) {
            log.info("Игрок {} удален", id);
        } else {
            log.info("Все игроки удалены");
        }
    }

}