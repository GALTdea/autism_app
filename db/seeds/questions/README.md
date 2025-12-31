# Question Import JSON Format

This directory contains JSON files for importing questions and their options into the application. Questions are organized by domain (e.g., Communication, Social Skills, Sensory Processing).

## Quick Start

1. **Create a template file:**
   ```bash
   bin/rails 'questions:create_template[my_questions.json]'
   ```

2. **Edit the JSON file** with your questions

3. **Import the questions:**
   ```bash
   bin/rails 'questions:import[my_questions.json]'
   ```

   Or import all JSON files at once:
   ```bash
   bin/rails questions:import
   ```

---

## JSON Format

The importer supports two formats:

### Format 1: Single Domain

Import questions for a single domain:

```json
{
  "domain": {
    "key": "communication",
    "label": "Communication Skills",
    "description": "Verbal and non-verbal communication abilities"
  },
  "questions": [
    {
      "code": "COMM_1",
      "text": "How does the child express basic needs?",
      "response_type": "scale",
      "position": 0,
      "options": [
        { "label": "Not at all", "value": 0, "position": 0 },
        { "label": "Rarely", "value": 1, "position": 1 },
        { "label": "Sometimes", "value": 2, "position": 2 },
        { "label": "Often", "value": 3, "position": 3 },
        { "label": "Always", "value": 4, "position": 4 }
      ]
    }
  ]
}
```

### Format 2: Multiple Domains

Import questions for multiple domains in one file:

```json
{
  "domains": [
    {
      "domain": {
        "key": "communication",
        "label": "Communication Skills"
      },
      "questions": [...]
    },
    {
      "domain": {
        "key": "social",
        "label": "Social Skills"
      },
      "questions": [...]
    }
  ]
}
```

---

## Domain Object

```json
{
  "key": "communication",           // Required: unique identifier (lowercase, alphanumeric + underscores)
  "label": "Communication Skills",  // Required: display name
  "description": "..."              // Optional: description of the domain
}
```

**Notes:**
- `key` must be unique across all domains
- If domain doesn't exist, it will be created automatically
- If domain exists, the import will update the label/description if provided

---

## Question Object

```json
{
  "code": "COMM_1",                          // Required: unique question code (UPPERCASE, alphanumeric + underscores)
  "text": "How does the child...",           // Required: question text
  "response_type": "scale",                  // Required: "scale", "multi_choice", or "text"
  "position": 0,                             // Optional: display order (auto-assigned if omitted)
  "options": [...]                           // Required for scale/multi_choice, empty array for text
}
```

### Response Types

#### 1. Scale Questions

Use for Likert scales (e.g., 0-4, 0-5):

```json
{
  "code": "COMM_1",
  "text": "How often does the child initiate communication?",
  "response_type": "scale",
  "position": 0,
  "options": [
    { "label": "Never", "value": 0, "position": 0 },
    { "label": "Rarely", "value": 1, "position": 1 },
    { "label": "Sometimes", "value": 2, "position": 2 },
    { "label": "Often", "value": 3, "position": 3 },
    { "label": "Always", "value": 4, "position": 4 }
  ]
}
```

**Requirements:**
- Must have at least one option
- Option `value` must be numeric (integer)
- Options should be ordered from lowest to highest value

#### 2. Multi-Choice Questions

Use for multiple choice with specific values:

```json
{
  "code": "SOCIAL_5",
  "text": "Which best describes the child's peer interaction?",
  "response_type": "multi_choice",
  "position": 4,
  "options": [
    { "label": "Prefers solitary play", "value": 0, "position": 0 },
    { "label": "Parallel play only", "value": 1, "position": 1 },
    { "label": "Basic interactive play", "value": 2, "position": 2 },
    { "label": "Engaged interactive play", "value": 3, "position": 3 }
  ]
}
```

**Requirements:**
- Must have at least one option
- Option `value` must be numeric (integer)

#### 3. Text Questions

Use for open-ended responses:

```json
{
  "code": "COMM_2",
  "text": "Describe the child's use of gestures to communicate.",
  "response_type": "text",
  "position": 1,
  "options": []
}
```

**Requirements:**
- `options` must be an empty array `[]`
- No options needed

---

## Question Option Object

```json
{
  "label": "Not at all",   // Required: display text for the option
  "value": 0,              // Required: numeric value for scoring (integer)
  "position": 0            // Optional: display order (auto-assigned if omitted)
}
```

**Notes:**
- `value` is used for scoring calculations (must be integer)
- `position` determines display order (0-based)
- If `position` is omitted, options are ordered by array index

---

## Question Code Format

**Format:** `{DOMAIN_KEY}_{NUMBER}`

**Examples:**
- `COMM_1`, `COMM_2`, `COMM_3` (Communication domain)
- `SOCIAL_1`, `SOCIAL_2` (Social domain)
- `SENSORY_1`, `SENSORY_2` (Sensory domain)

**Rules:**
- Must be UPPERCASE
- Only letters, numbers, and underscores
- Must be globally unique (across all questions)
- Recommended: Use domain prefix + sequential number

**Auto-generation:**
- If you're using the UI to create questions, codes are auto-generated
- For imports, you must provide the code explicitly

---

## Complete Example

Here's a complete example with multiple questions of different types:

```json
{
  "domain": {
    "key": "communication",
    "label": "Communication Skills",
    "description": "Assessment of verbal and non-verbal communication abilities"
  },
  "questions": [
    {
      "code": "COMM_1",
      "text": "How often does the child initiate communication with others?",
      "response_type": "scale",
      "position": 0,
      "options": [
        { "label": "Never", "value": 0, "position": 0 },
        { "label": "Rarely", "value": 1, "position": 1 },
        { "label": "Sometimes", "value": 2, "position": 2 },
        { "label": "Often", "value": 3, "position": 3 },
        { "label": "Always", "value": 4, "position": 4 }
      ]
    },
    {
      "code": "COMM_2",
      "text": "Describe the child's use of gestures, pointing, or other non-verbal communication methods.",
      "response_type": "text",
      "position": 1,
      "options": []
    },
    {
      "code": "COMM_3",
      "text": "What is the child's primary method of expressing needs?",
      "response_type": "multi_choice",
      "position": 2,
      "options": [
        { "label": "Crying or tantrums only", "value": 0, "position": 0 },
        { "label": "Pointing or gestures", "value": 1, "position": 1 },
        { "label": "Single words", "value": 2, "position": 2 },
        { "label": "Short phrases", "value": 3, "position": 3 },
        { "label": "Full sentences", "value": 4, "position": 4 }
      ]
    }
  ]
}
```

---

## Multi-Domain Example

```json
{
  "domains": [
    {
      "domain": {
        "key": "communication",
        "label": "Communication Skills"
      },
      "questions": [
        {
          "code": "COMM_1",
          "text": "Question text here...",
          "response_type": "scale",
          "position": 0,
          "options": [
            { "label": "Option 1", "value": 0, "position": 0 },
            { "label": "Option 2", "value": 1, "position": 1 }
          ]
        }
      ]
    },
    {
      "domain": {
        "key": "social",
        "label": "Social Skills"
      },
      "questions": [
        {
          "code": "SOCIAL_1",
          "text": "Another question...",
          "response_type": "scale",
          "position": 0,
          "options": [
            { "label": "Option 1", "value": 0, "position": 0 },
            { "label": "Option 2", "value": 1, "position": 1 }
          ]
        }
      ]
    }
  ]
}
```

---

## Validation Rules

### Domain Validation
- ✅ `key` is required and must be unique
- ✅ `label` is required
- ✅ `description` is optional

### Question Validation
- ✅ `code` is required and must be unique (globally)
- ✅ `code` must match format: uppercase letters, numbers, underscores only
- ✅ `text` is required
- ✅ `response_type` must be one of: `"scale"`, `"multi_choice"`, `"text"`
- ✅ `position` is optional (auto-assigned if omitted)
- ✅ `options` is required array (can be empty for text questions)

### Option Validation
- ✅ `label` is required
- ✅ `value` is required and must be numeric (integer)
- ✅ `position` is optional (auto-assigned if omitted)

### Response Type Requirements
- ✅ `scale` questions: must have at least 1 option
- ✅ `multi_choice` questions: must have at least 1 option
- ✅ `text` questions: must have empty options array `[]`

---

## Import Behavior

### Idempotent Imports
- **Questions are updated by code**: If a question with the same `code` exists, it will be updated (not duplicated)
- **Domains are created if missing**: If domain `key` doesn't exist, it will be created automatically
- **Options are replaced**: When updating a question, existing options are cleared and new ones are created

### Import Results
After importing, you'll see a summary:
- ✅ Domains created
- ✅ Questions imported (new)
- 🔄 Questions updated (existing)
- ⚠️ Warnings (non-critical issues)
- ❌ Errors (import failures)

---

## Tips for ChatGPT Generation

When asking ChatGPT to generate questions, use prompts like:

> "Generate a complete autism assessment question set in JSON format. Include:
> - A communication domain with 5 scale questions (0-4 scale)
> - Each question should have a unique code like COMM_1, COMM_2, etc.
> - Use the format: { domain: { key, label, description }, questions: [...] }"

Or:

> "Create JSON for importing autism assessment questions. Format should be:
> { domains: [{ domain: {...}, questions: [...] }] }
> Include domains: communication, social, sensory, flexibility, emotional_regulation
> Each domain should have 3-5 questions with appropriate response types."

---

## Common Issues

### Error: "Question code already exists"
- **Solution**: Question with that code already exists. Use a different code or the existing question will be updated.

### Error: "Invalid code format"
- **Solution**: Code must be UPPERCASE with only letters, numbers, and underscores (e.g., `COMM_1`, not `comm-1`).

### Error: "Scale questions require at least one option"
- **Solution**: Add options array with at least one option for scale/multi_choice questions.

### Warning: "Question belongs to different domain"
- **Info**: Question exists but is in a different domain. It will be moved to the new domain.

---

## File Naming Suggestions

Use descriptive names:
- `communication_questions.json`
- `social_skills_questions.json`
- `full_assessment_v1.json`
- `preschool_assessment.json`

---

## Need Help?

- Run `bin/rails 'questions:create_template[example.json]'` to generate a template
- Check import results for warnings and errors
- Verify questions in the UI after importing

