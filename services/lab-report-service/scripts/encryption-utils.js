#!/usr/bin/env node

/**
 * Lab Report Encryption Utilities
 *
 * This script provides utilities for:
 * 1. Generating secure encryption keys
 * 2. Testing encryption/decryption
 * 3. Migrating existing unencrypted data
 */

import { randomBytes, createCipheriv, createDecipheriv } from "crypto";

class EncryptionUtils {
  /**
   * Generate a new secure encryption key
   */
  static generateKey() {
    const key = randomBytes(32).toString("hex");
    console.log("🔑 Generated new encryption key:");
    console.log(`LAB_DATA_ENCRYPTION_KEY=${key}`);
    console.log(
      "\n⚠️  Important: Store this key securely and never commit it to version control!"
    );
    return key;
  }

  /**
   * Test encryption with sample data
   */
  static testEncryption(key) {
    try {
      const testData = {
        hemoglobin: "14.5 g/dL",
        whiteBloodCells: "7500 /μL",
        platelets: "250000 /μL",
        glucose: "95 mg/dL",
        cholesterol: "180 mg/dL",
      };

      console.log("🧪 Testing encryption with sample lab data...");
      console.log("Original data:", testData);

      // Mock encryption (you'd use your actual EncryptionService here)
      const algorithm = "aes-256-gcm";
      const keyBuffer = Buffer.from(key, "hex");
      const iv = randomBytes(16);

      const cipher = createCipheriv(algorithm, keyBuffer, iv);
      cipher.setAAD(Buffer.from("labdata", "utf8"));

      let encrypted = cipher.update(JSON.stringify(testData), "utf8", "hex");
      encrypted += cipher.final("hex");

      const tag = cipher.getAuthTag();
      const encryptedString =
        iv.toString("hex") + ":" + tag.toString("hex") + ":" + encrypted;

      console.log("✅ Encrypted successfully");
      console.log("Encrypted length:", encryptedString.length, "characters");

      // Test decryption
      const parts = encryptedString.split(":");
      const ivDecrypt = Buffer.from(parts[0], "hex");
      const tagDecrypt = Buffer.from(parts[1], "hex");
      const encryptedData = parts[2];

      const decipher = createDecipheriv(algorithm, keyBuffer, ivDecrypt);
      decipher.setAAD(Buffer.from("labdata", "utf8"));
      decipher.setAuthTag(tagDecrypt);

      let decrypted = decipher.update(encryptedData, "hex", "utf8");
      decrypted += decipher.final("utf8");

      const decryptedData = JSON.parse(decrypted);
      console.log("✅ Decrypted successfully");
      console.log("Decrypted data:", decryptedData);

      const isMatch =
        JSON.stringify(testData) === JSON.stringify(decryptedData);
      console.log(
        isMatch ? "✅ Encryption test PASSED" : "❌ Encryption test FAILED"
      );
    } catch (error) {
      console.error("❌ Encryption test failed:", error.message);
    }
  }

  /**
   * Display security recommendations
   */
  static showSecurityTips() {
    console.log("\n🔐 SECURITY RECOMMENDATIONS:");
    console.log(
      "1. Store encryption keys in secure key management systems (AWS KMS, Azure Key Vault)"
    );
    console.log(
      "2. Use different keys for different environments (dev/staging/prod)"
    );
    console.log("3. Implement key rotation policies (every 90-180 days)");
    console.log("4. Monitor access to encrypted data");
    console.log("5. Backup data before key rotation");
    console.log("6. Use HTTPS/TLS for data in transit");
    console.log("7. Implement proper access controls and audit logging");
    console.log(
      "8. Consider using additional authentication (2FA) for key access"
    );
  }
}

// CLI interface
const command = process.argv[2];
const keyArg = process.argv[3];

switch (command) {
  case "generate-key":
    EncryptionUtils.generateKey();
    break;

  case "test":
    if (!keyArg) {
      console.error(
        "❌ Please provide a key to test with: node encryption-utils.js test <your-key>"
      );
      process.exit(1);
    }
    EncryptionUtils.testEncryption(keyArg);
    break;

  case "security-tips":
    EncryptionUtils.showSecurityTips();
    break;

  default:
    console.log("🔧 Lab Report Encryption Utilities\n");
    console.log("Usage:");
    console.log(
      "  node encryption-utils.js generate-key          # Generate a new encryption key"
    );
    console.log(
      "  node encryption-utils.js test <key>           # Test encryption with a key"
    );
    console.log(
      "  node encryption-utils.js security-tips        # Display security recommendations"
    );
    console.log("\nExample:");
    console.log("  node encryption-utils.js generate-key");
    console.log("  node encryption-utils.js test 1234567890abcdef...");
}
