package com.example.kafkamicro.config;

import com.example.kafkamicro.dto.PlayerCommand;
import org.apache.kafka.clients.consumer.ConsumerConfig;
import org.apache.kafka.common.serialization.StringDeserializer;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.kafka.config.ConcurrentKafkaListenerContainerFactory;
import org.springframework.kafka.core.ConsumerFactory;
import org.springframework.kafka.core.DefaultKafkaConsumerFactory;
import org.springframework.kafka.support.serializer.JsonDeserializer;

import java.util.HashMap;
import java.util.Map;

@Configuration
public class KafkaConsumerConfig {

    @Value("${spring.kafka.bootstrap-servers}")
    private String bootstrapServers;

    @Value("${spring.kafka.consumer.group-id}")
    private String groupId;

    /**
     * Фабрика consumer'ов - создает объекты для чтения из Kafka
     */
    @Bean
    public ConsumerFactory<String, PlayerCommand> consumerFactory() {
        Map<String, Object> props = new HashMap<>();

        // Адрес Kafka брокера
        props.put(ConsumerConfig.BOOTSTRAP_SERVERS_CONFIG, bootstrapServers);

        // ID группы consumer'ов (важно: все consumer'ы с одним groupId делят нагрузку)
        props.put(ConsumerConfig.GROUP_ID_CONFIG, groupId);

        // С чего начинать читать, если нет сохраненного offset'а
        // "earliest" - с самого начала, "latest" - только новые
        props.put(ConsumerConfig.AUTO_OFFSET_RESET_CONFIG, "earliest");

        // Отключаем авто-коммит (будем подтверждать вручную после успешной обработки)
        props.put(ConsumerConfig.ENABLE_AUTO_COMMIT_CONFIG, false);

        // Максимум сообщений за один poll()
        props.put(ConsumerConfig.MAX_POLL_RECORDS_CONFIG, 10);

        // --- Настройка десериализаторов ---
        // Ключ - String
        props.put(ConsumerConfig.KEY_DESERIALIZER_CLASS_CONFIG, StringDeserializer.class);

        // Значение - JSON -> PlayerCommand
        props.put(ConsumerConfig.VALUE_DESERIALIZER_CLASS_CONFIG, JsonDeserializer.class);

        // Важно! Указываем, какой класс ожидаем в значении
        props.put(JsonDeserializer.TRUSTED_PACKAGES, "com.example.kafkamicro.dto");

        return new DefaultKafkaConsumerFactory<>(props);
    }

    /**
     * Фабрика listener'ов - создает контейнеры, которые будут слушать топики
     */
    @Bean
    public ConcurrentKafkaListenerContainerFactory<String, PlayerCommand>
    kafkaListenerContainerFactory() {

        ConcurrentKafkaListenerContainerFactory<String, PlayerCommand> factory =
                new ConcurrentKafkaListenerContainerFactory<>();
        factory.setConsumerFactory(consumerFactory());

        // Количество потоков-слушателей (для параллельной обработки)
        factory.setConcurrency(3);

        return factory;
    }
}