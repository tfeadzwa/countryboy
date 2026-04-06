# Code Format Standards

All Countryboy codes follow a strict **6-character format** for consistency, professionalism, and ease of use.

---

## 📋 Format Specifications

### 1. Merchant Code (Depot Identifier)

**Format:** `XXX###`

- **X** = Uppercase letter (location code)
- **#** = Digit (0-9)

**Purpose:** Uniquely identifies each depot/branch

**Examples:**
| Location | Code | Depot Name |
|----------|------|------------|
| Harare | `HRE001` | Harare Central Depot |
| Harare | `HRE002` | Harare Airport Branch |
| Bulawayo | `BYO001` | Bulawayo Main Depot |
| Gweru | `GWE001` | Gweru Depot |
| Mutare | `MUT001` | Mutare Depot |

**Usage:** Entered by conductor during daily login

---

### 2. Agent Code (Conductor Identifier)

**Format:** `XXX###`

- **X** = Uppercase letter (agent initials)
- **#** = Digit (0-9) (sequence number per depot)

**Purpose:** Uniquely identifies each conductor/agent

**Examples:**
| Agent Name | Initials | Code |
|------------|----------|------|
| Tapiwa Moyo | TMO | `TMO014` |
| John Dube | JDU | `JDU003` |
| Kelvin Ncube | KNC | `KNC021` |
| Sarah Ndlovu | SND | `SND008` |
| Michael Chikwanha | MCH | `MCH055` |

**Assignment Rules:**
- Use first 3 letters of first name + last name
- If name shorter, pad with initials: "Jo Lee" → `JLE`
- For same initials, use middle initial: "John M. Dube" → `JMD`

**Sequence Numbers:**
- Start at 001 for each depot
- Increment sequentially
- Leading zeros required (001, not 1)

**Usage:** Entered by conductor during daily login

---

### 3. Pairing Code (Device Setup)

**Format:** `XXX###` or `XXX-###`

- **X** = Uppercase letter (NO ambiguous chars: O, I, L)
- **#** = Digit (NO zero or one: 2-9 only)

**Purpose:** One-time device pairing during initial setup

**Examples:**
- `ABC234`
- `K7M952`
- `DEF-456` (dash optional for readability)
- `PQR387`

**Character Exclusions:**
- Letters: O, I, L (look like 0, 1, 1)
- Digits: 0, 1 (look like O, I)

**Usage:** Entered ONCE by conductor during device pairing

---

## ✅ Validation Rules

### Backend Validation (Enforced)

**Merchant Code:**
```regex
^[A-Z]{3}\d{3}$
```
- Exactly 6 characters
- First 3: uppercase letters
- Last 3: digits 0-9

**Agent Code:**
```regex
^[A-Z]{3}\d{3}$
```
- Exactly 6 characters
- First 3: uppercase letters
- Last 3: digits 0-9

**Pairing Code:**
```regex
^[ABCDEFGHJKMNPQRSTUVWXYZ]{3}[2-9]{3}$
```
- Exactly 6 characters (without dash)
- First 3: letters (excluding O, I, L)
- Last 3: digits 2-9

### Error Messages

**Invalid Format:**
```json
{
  "error": "Merchant code must be 3 uppercase letters + 3 digits (e.g., HRE001)"
}
```

**Duplicate:**
```json
{
  "error": "Merchant code already exists: HRE001"
}
```

---

## 💡 User Experience Benefits

1. **Easy to Type** - Only 6 characters
2. **Easy to Remember** - Meaningful codes (location or initials)
3. **Professional** - Consistent format across all documentation
4. **Error-Resistant** - Validation catches typos immediately
5. **Human-Readable** - Can be read aloud over phone without confusion
6. **Ticket-Friendly** - Fits nicely on printed receipts

---

## 📱 Mobile App Input Guidelines

### Merchant Code Input
- Auto-uppercase as user types
- Show format hint: "HRE001"
- Max length: 6 characters
- Accept only letters (first 3) and digits (last 3)

### Agent Code Input
- Auto-uppercase as user types
- Show format hint: "TMO014"
- Max length: 6 characters
- Accept only letters (first 3) and digits (last 3)

### Pairing Code Input
- Auto-uppercase as user types
- Accept dash but strip before validation
- Show format hint: "ABC-234"
- Display "No O, I, L, 0, or 1" note

---

## 🎯 Implementation Checklist

- [x] Database schema enforces length constraints
- [x] Backend validation with regex patterns
- [x] Validation error messages are user-friendly
- [x] Postman examples updated
- [x] Documentation updated
- [ ] Mobile app input fields with auto-uppercase
- [ ] Mobile app format hints/placeholders
- [ ] Admin portal validation
- [ ] Admin portal helper text
- [ ] Printed tickets show codes correctly

---

## 📞 Support Examples

**When helping conductor over phone:**

> "Enter merchant code: **H** as in Hotel, **R** as in Romeo, **E** as in Echo, **zero zero one**"

> "Enter agent code: **T** as in Tango, **M** as in Mike, **O** as in Oscar, **zero one four**"

**Clear pronunciation prevents errors!**
