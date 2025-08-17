import ballerina/kafka;
import ballerina/log;

# Kafka client configuration
public type KafkaConfig record {
    string bootstrapServers;
    string groupId?;
    string keyDeserializer?;
    string valueDeserializer?;
};

# Kafka producer client
public class KafkaProducer {
    private kafka:Producer producer;

    public function init(KafkaConfig config) returns error? {
        kafka:ProducerConfiguration producerConfig = {
            bootstrapServers: config.bootstrapServers,
            keySerializerType: kafka:SER_STRING,
            valueSerializerType: kafka:SER_STRING
        };
        
        self.producer = check new (producerConfig);
        log:printInfo("Kafka producer initialized successfully");
    }

    # Send a message to a topic
    public function send(string topic, string message, string? key = ()) returns error? {
        kafka:ProducerRecord record = {
            topic: topic,
            value: message,
            key: key
        };
        return self.producer->send(record);
    }

    # Send a message and flush immediately
    public function sendAndFlush(string topic, string message, string? key = ()) returns error? {
        check self.send(topic, message, key);
        return self.producer->flushRecords();
    }

    # Close the producer
    public function close() returns error? {
        return self.producer->close();
    }
}

# Kafka consumer client
public class KafkaConsumer {
    private kafka:Consumer consumer;

    public function init(KafkaConfig config, string[] topics) returns error? {
        kafka:ConsumerConfiguration consumerConfig = {
            bootstrapServers: config.bootstrapServers,
            groupId: config.groupId ?: "default-group",
            topics: topics,
            keyDeserializerType: kafka:DES_STRING,
            valueDeserializerType: kafka:DES_STRING
        };
        
        self.consumer = check new (consumerConfig);
        log:printInfo("Kafka consumer initialized successfully");
    }

    # Poll for messages
    public function poll(int timeoutMs = 1000) returns kafka:ConsumerRecord[]|error {
        return self.consumer->poll(timeoutMs);
    }

    # Commit the current offset
    public function commit() returns error? {
        return self.consumer->commit();
    }

    # Close the consumer
    public function close() returns error? {
        return self.consumer->close();
    }
}
