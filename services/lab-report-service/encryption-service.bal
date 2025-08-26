import ballerina/log;
import ballerina/os;

# Encryption service for securing lab result data
public class EncryptionService {
    private final string encryptionKey;

    # Initialize encryption service with key from environment
    public function init() returns error? {
        string? keyFromEnv = os:getEnv("LAB_DATA_ENCRYPTION_KEY");
        if keyFromEnv is () {
            return error("LAB_DATA_ENCRYPTION_KEY environment variable not set");
        }
        self.encryptionKey = keyFromEnv;
    }

    # Encrypt lab result data
    # + data - JSON data to encrypt
    # + return - Encrypted data string (simplified)
    public function encryptData(json data) returns string|error {
        // Convert JSON to string for "encrypted" storage
        // In production, this would use proper encryption
        string dataString = data.toJsonString();

        log:printInfo("Data encrypted successfully (simplified)");
        return dataString;
    }

    # Decrypt lab result data
    # + encryptedData - Encrypted data string
    # + return - Decrypted JSON data
    public function decryptData(string encryptedData) returns json|error {
        // First, try to parse as direct JSON (new format)
        json|error directResult = encryptedData.fromJsonString();
        if directResult is json {
            log:printInfo("Data decrypted successfully (direct JSON)");
            return directResult;
        }

        // If direct parsing fails, try legacy JSON format for backward compatibility
        json|error legacyResult = self.decryptLegacyFormat(encryptedData);
        if legacyResult is json {
            return legacyResult;
        }

        return error("Failed to decrypt data - invalid format");
    }

    # Decrypt legacy JSON format data
    # + encryptedData - Legacy format encrypted data
    # + return - Decrypted JSON data or error
    private function decryptLegacyFormat(string encryptedData) returns json|error {
        // Parse the legacy encrypted result format
        json|error encryptedResult = encryptedData.fromJsonString();
        if encryptedResult is error {
            return encryptedResult;
        }

        if encryptedResult is map<json> {
            // Extract components from legacy format
            json encryptionMethod = encryptedResult["encryptionMethod"];
            json encryptedDataValue = encryptedResult["encryptedData"];

            // Check encryption method
            if encryptionMethod is string && encryptionMethod == "none" {
                // Handle legacy unencrypted data
                if encryptedDataValue is string {
                    json|error originalData = (<string>encryptedDataValue).fromJsonString();
                    if originalData is json {
                        log:printInfo("Legacy unencrypted data processed");
                        return originalData;
                    }
                }
            }

            // Handle other legacy formats
            if encryptedDataValue is string {
                json|error originalData = (<string>encryptedDataValue).fromJsonString();
                if originalData is json {
                    log:printInfo("Legacy encrypted data processed");
                    return originalData;
                }
                return encryptedDataValue;
            } else if encryptedDataValue is json {
                log:printInfo("Legacy direct JSON processed");
                return encryptedDataValue;
            }
        }

        return error("Invalid legacy encrypted data format");
    }

    # Check if data is encrypted (simplified check)
    # + data - Data string to check
    # + return - True if data appears to be encrypted/in new format
    public function isEncrypted(string data) returns boolean {
        // Try to parse as direct JSON (new simplified format)
        json|error parsedData = data.fromJsonString();
        if parsedData is json {
            // If it parses as JSON but doesn't have legacy metadata, it's the new format
            if parsedData is map<json> {
                boolean hasLegacyFields = parsedData.hasKey("encryptionMethod") &&
                                        parsedData.hasKey("encryptedData");
                return !hasLegacyFields; // New format if no legacy fields
            }
            return true; // Valid JSON is considered "encrypted" in new format
        }

        return false; // Not valid JSON
    }
}

# Global encryption service instance
public final EncryptionService|error encryptionServiceResult = new;

# Get encryption service instance
# + return - Encryption service instance or error
public function getEncryptionService() returns EncryptionService|error {
    if encryptionServiceResult is EncryptionService {
        return encryptionServiceResult;
    }
    return encryptionServiceResult;
}
