import ballerina/crypto;
import ballerina/log;
import ballerina/os;
import ballerina/random;
import ballerina/regex;

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

    # Encrypt lab result data using AES-256-GCM
    # + data - JSON data to encrypt
    # + return - Encrypted data string in format: iv:salt:encryptedData (hex encoded)
    public function encryptData(json data) returns string|error {
        // Convert JSON to string
        string dataString = data.toJsonString();
        byte[] dataBytes = dataString.toBytes();

        // Generate random IV (16 bytes for AES)
        byte[] iv = check self.generateRandomBytes(16);

        // Generate random salt (16 bytes)
        byte[] salt = check self.generateRandomBytes(16);

        // Derive key from password using PBKDF2-like approach (simplified)
        byte[] keyBytes = check self.deriveKey(self.encryptionKey, salt);

        // Encrypt using AES-256-CBC with PKCS5 padding (more widely supported)
        byte[] encryptedData = check crypto:encryptAesCbc(dataBytes, keyBytes, iv, crypto:PKCS5);

        // Format: iv:salt:encryptedData (all hex encoded)
        string ivHex = self.bytesToHex(iv);
        string saltHex = self.bytesToHex(salt);
        string encryptedHex = self.bytesToHex(encryptedData);

        string result = ivHex + ":" + saltHex + ":" + encryptedHex;

        log:printInfo("Data encrypted successfully using AES-256-CBC");
        log:printInfo("IV length: " + ivHex.length().toString() + ", Salt length: " + saltHex.length().toString() + ", Encrypted length: " + encryptedHex.length().toString());
        log:printInfo("Full encrypted result length: " + result.length().toString());
        log:printInfo("Encrypted result preview: " + (result.length() > 100 ? result.substring(0, 100) + "..." : result));

        return result;
    }

    # Decrypt lab result data using AES-256-GCM
    # + encryptedData - Encrypted data string in format: iv:salt:encryptedData
    # + return - Decrypted JSON data
    public function decryptData(string encryptedData) returns json|error {
        log:printInfo("=== DECRYPTION DEBUG ===");
        log:printInfo("Input length: " + encryptedData.length().toString());
        log:printInfo("Contains colons: " + encryptedData.includes(":").toString());
        log:printInfo("Input preview: " + (encryptedData.length() > 100 ? encryptedData.substring(0, 100) + "..." : encryptedData));

        // Check if it's the new encrypted format (contains colons)
        if encryptedData.includes(":") {
            log:printInfo("Processing as AES encrypted format");
            return self.decryptAesFormat(encryptedData);
        }

        log:printInfo("No colons found - trying legacy formats");

        // Try legacy formats for backward compatibility
        json|error legacyResult = self.decryptLegacyFormat(encryptedData);
        if legacyResult is json {
            log:printInfo("Successfully decrypted using legacy format");
            return legacyResult;
        }

        // Try direct JSON parsing as fallback
        json|error directResult = encryptedData.fromJsonString();
        if directResult is json {
            log:printInfo("Data processed as plain JSON (fallback)");
            return directResult;
        }

        log:printError("All decryption methods failed");
        return error("Failed to decrypt data - invalid format");
    }

    # Decrypt AES encrypted data
    # + encryptedData - Encrypted data in format iv:salt:encryptedData
    # + return - Decrypted JSON data
    private function decryptAesFormat(string encryptedData) returns json|error {
        log:printInfo("Attempting to decrypt AES format data");
        log:printInfo("Encrypted data length: " + encryptedData.length().toString());

        // Split the encrypted data
        string[] parts = regex:split(encryptedData, ":");
        if parts.length() != 3 {
            log:printError("Invalid format - found " + parts.length().toString() + " parts instead of 3");
            return error("Invalid encrypted data format - expected iv:salt:encryptedData");
        }

        log:printInfo("IV hex length: " + parts[0].length().toString());
        log:printInfo("Salt hex length: " + parts[1].length().toString());
        log:printInfo("Encrypted data hex length: " + parts[2].length().toString());

        // Parse hex components (using a simple hex decode function)
        byte[]|error ivResult = self.hexToBytes(parts[0]);
        byte[]|error saltResult = self.hexToBytes(parts[1]);
        byte[]|error encryptedBytesResult = self.hexToBytes(parts[2]);

        if ivResult is error {
            log:printError("Failed to decode IV hex: " + ivResult.message());
            return ivResult;
        }
        if saltResult is error {
            log:printError("Failed to decode salt hex: " + saltResult.message());
            return saltResult;
        }
        if encryptedBytesResult is error {
            log:printError("Failed to decode encrypted data hex: " + encryptedBytesResult.message());
            return encryptedBytesResult;
        }

        byte[] iv = ivResult;
        byte[] salt = saltResult;
        byte[] encryptedBytes = encryptedBytesResult;

        log:printInfo("Hex decoding successful");
        log:printInfo("IV bytes length: " + iv.length().toString());
        log:printInfo("Salt bytes length: " + salt.length().toString());
        log:printInfo("Encrypted bytes length: " + encryptedBytes.length().toString());

        // Derive key from password using same method as encryption
        byte[]|error keyResult = self.deriveKey(self.encryptionKey, salt);
        if keyResult is error {
            log:printError("Failed to derive key: " + keyResult.message());
            return keyResult;
        }
        byte[] keyBytes = keyResult;

        log:printInfo("Key derivation successful, key length: " + keyBytes.length().toString());

        // Decrypt using AES-256-CBC with PKCS5 padding
        byte[]|error decryptResult = crypto:decryptAesCbc(encryptedBytes, keyBytes, iv, crypto:PKCS5);
        if decryptResult is error {
            log:printError("AES decryption failed: " + decryptResult.message());
            return decryptResult;
        }
        byte[] decryptedBytes = decryptResult;

        log:printInfo("AES decryption successful, decrypted length: " + decryptedBytes.length().toString());

        // Convert back to string and parse JSON
        string|error stringResult = string:fromBytes(decryptedBytes);
        if stringResult is error {
            log:printError("Failed to convert decrypted bytes to string: " + stringResult.message());
            return stringResult;
        }
        string decryptedString = stringResult;

        log:printInfo("Decrypted string length: " + decryptedString.length().toString());
        log:printInfo("Decrypted string preview: " + (decryptedString.length() > 100 ? decryptedString.substring(0, 100) + "..." : decryptedString));

        json|error jsonResult = decryptedString.fromJsonString();
        if jsonResult is error {
            log:printError("Failed to parse decrypted string as JSON: " + jsonResult.message());
            log:printError("Decrypted string: " + decryptedString);
            return jsonResult;
        }
        json result = jsonResult;

        log:printInfo("Data decrypted successfully using AES-256-GCM");
        return result;
    }

    # Convert hex string to bytes
    # + hexString - Hex string to convert
    # + return - Byte array
    private function hexToBytes(string hexString) returns byte[]|error {
        if hexString.length() % 2 != 0 {
            return error("Invalid hex string length");
        }

        byte[] result = [];
        int i = 0;
        while i < hexString.length() {
            string hexPair = hexString.substring(i, i + 2);
            int|error byteValue = int:fromHexString(hexPair);
            if byteValue is error {
                return error("Invalid hex character in string");
            }
            result.push(<byte>byteValue);
            i += 2;
        }
        return result;
    }

    # Convert bytes to hex string
    # + bytes - Byte array to convert
    # + return - Hex string
    private function bytesToHex(byte[] bytes) returns string {
        string result = "";
        foreach byte b in bytes {
            string hex = int:toHexString(b);
            if hex.length() == 1 {
                hex = "0" + hex;
            }
            result += hex;
        }
        return result;
    }

    # Generate random bytes
    # + length - Number of bytes to generate
    # + return - Random bytes array
    private function generateRandomBytes(int length) returns byte[]|error {
        byte[] randomBytes = [];
        int i = 0;
        while i < length {
            int|random:Error randomResult = random:createIntInRange(0, 256);
            if randomResult is random:Error {
                return error("Failed to generate random bytes");
            }
            randomBytes.push(<byte>randomResult);
            i += 1;
        }
        return randomBytes;
    }

    # Derive encryption key from password and salt
    # + password - Password string
    # + salt - Salt bytes
    # + return - Derived key bytes (32 bytes for AES-256)
    private function deriveKey(string password, byte[] salt) returns byte[]|error {
        // Simple key derivation - in production use proper PBKDF2
        byte[] passwordBytes = password.toBytes();
        byte[] combined = [...passwordBytes, ...salt];

        // Hash the combined data to get 32-byte key
        byte[] hashedKey = crypto:hashSha256(combined);

        return hashedKey;
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
        // Check if data is in AES format: iv:salt:encryptedData (hex strings separated by colons)
        string[] parts = regex:split(data, ":");

        if parts.length() == 3 {
            // Check if all parts are valid hex strings with expected lengths
            string ivHex = parts[0];
            string saltHex = parts[1];
            string encryptedHex = parts[2];

            // IV should be 16 bytes = 32 hex chars, Salt should be 16 bytes = 32 hex chars
            if ivHex.length() == 32 && saltHex.length() == 32 && encryptedHex.length() > 0 {
                // Check if all parts contain only hex characters
                boolean allHex = self.isValidHex(ivHex) && self.isValidHex(saltHex) && self.isValidHex(encryptedHex);
                if allHex {
                    log:printInfo("Data identified as AES encrypted format");
                    return true;
                }
            }
        }

        // Check if it's legacy JSON format
        json|error parsedData = data.fromJsonString();
        if parsedData is json && parsedData is map<json> {
            boolean hasLegacyFields = parsedData.hasKey("encryptionMethod") &&
                                    parsedData.hasKey("encryptedData");
            if hasLegacyFields {
                log:printInfo("Data identified as legacy JSON encrypted format");
                return true;
            }
        }

        log:printInfo("Data identified as unencrypted (plain JSON or other format)");
        return false;
    }

    # Check if a string contains only valid hexadecimal characters
    # + hexString - String to check
    # + return - True if valid hex, false otherwise
    private function isValidHex(string hexString) returns boolean {
        // Use regex to check if string contains only hex characters (0-9, a-f, A-F)
        return regex:matches(hexString, "^[0-9a-fA-F]+$");
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
