import { v4 as uuidv4 } from 'uuid';

/**
 * Generate a memorable 6-character pairing code for device setup
 * Format: ABC123 or ABC-123
 * Excludes ambiguous characters: 0, O, 1, I, L
 * @param withDash - Whether to include dash separator (ABC-123)
 * @returns 6-character alphanumeric code
 */
export function generatePairingCode(withDash: boolean = false): string {
  // Exclude ambiguous: 0, O, 1, I, L
  const letters = 'ABCDEFGHJKMNPQRSTUVWXYZ'; // 23 letters
  const numbers = '23456789'; // 7 numbers
  
  let code = '';
  
  // First 3 characters: letters
  for (let i = 0; i < 3; i++) {
    code += letters[Math.floor(Math.random() * letters.length)];
  }
  
  if (withDash) code += '-';
  
  // Last 3 characters: numbers
  for (let i = 0; i < 3; i++) {
    code += numbers[Math.floor(Math.random() * numbers.length)];
  }
  
  return code;
}

/**
 * Generate a long secure token for API authentication
 * @returns UUID v4 string
 */
export function generateDeviceToken(): string {
  return uuidv4();
}

/**
 * Validate pairing code format
 * @param code - Code to validate
 * @returns true if valid format
 */
export function isValidPairingCode(code: string): boolean {
  // Remove dash if present
  const normalized = code.replace('-', '');
  
  // Must be exactly 6 characters
  if (normalized.length !== 6) return false;
  
  // First 3 must be letters, last 3 must be numbers
  const pattern = /^[A-Z]{3}[2-9]{3}$/;
  return pattern.test(normalized);
}
