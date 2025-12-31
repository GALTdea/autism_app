# ChatGPT Prompt for Generating Question Import JSON

Copy and paste this prompt to ChatGPT when generating assessment questions:

---

## Your Role

You are generating a JSON file for importing autism assessment questions into a Rails application. The JSON must follow this exact format.

## Required JSON Structure

Generate JSON in one of these two formats:

### Format 1: Single Domain

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
    },
    {
      "code": "COMM_2",
      "text": "Describe the child's use of gestures to communicate.",
      "response_type": "text",
      "position": 1,
      "options": []
    }
  ]
}
```

### Format 2: Multiple Domains

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

## Domain Object Requirements

Each domain must have:
- **key** (required): lowercase, alphanumeric + underscores only (e.g., "communication", "social_skills", "sensory_processing")
- **label** (required): human-readable display name (e.g., "Communication Skills")
- **description** (optional): description of what this domain assesses

## Question Object Requirements

Each question must have:
- **code** (required): UPPERCASE, alphanumeric + underscores only, format: `{DOMAIN_PREFIX}_{NUMBER}` 
  - Examples: `COMM_1`, `COMM_2`, `SOCIAL_1`, `SENSORY_1`
  - Must be unique globally
- **text** (required): the question text
- **response_type** (required): must be one of:
  - `"scale"` - for Likert scales (0-4 or 0-5)
  - `"multi_choice"` - for multiple choice with numeric values
  - `"text"` - for open-ended text responses
- **position** (optional): display order (integer, starts at 0). If omitted, will auto-assign.
- **options** (required): array of option objects (see below)

## Response Type Rules

### Scale Questions (`"response_type": "scale"`)
- Use for Likert scales (0-4 or 0-5)
- **Must have at least 1 option**
- Options should range from lowest to highest (e.g., 0-4 or 0-5)
- Example:
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

### Multi-Choice Questions (`"response_type": "multi_choice"`)
- Use for multiple choice with specific scoring values
- **Must have at least 1 option**
- Example:
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

### Text Questions (`"response_type": "text"`)
- Use for open-ended responses
- **Must have empty options array** `[]`
- Example:
```json
{
  "code": "COMM_2",
  "text": "Describe the child's use of gestures to communicate.",
  "response_type": "text",
  "position": 1,
  "options": []
}
```

## Option Object Requirements

Each option must have:
- **label** (required): the display text for this option
- **value** (required): numeric value for scoring (integer, e.g., 0, 1, 2, 3, 4)
- **position** (optional): display order (integer, starts at 0). If omitted, will use array index.

## Code Naming Convention

- Format: `{DOMAIN_PREFIX}_{NUMBER}`
- Domain prefix should match the domain key (uppercase)
- Start numbering from 1
- Examples:
  - Communication domain (`key: "communication"`) → `COMM_1`, `COMM_2`, `COMM_3`
  - Social domain (`key: "social"`) → `SOCIAL_1`, `SOCIAL_2`, `SOCIAL_3`
  - Sensory domain (`key: "sensory"`) → `SENSORY_1`, `SENSORY_2`, `SENSORY_3`

## Critical Rules

1. **Question codes must be UPPERCASE** and match pattern: letters, numbers, underscores only
2. **Domain keys must be lowercase** with underscores for spaces
3. **Scale and multi_choice questions MUST have options** (at least 1)
4. **Text questions MUST have empty options array** `[]`
5. **Option values must be integers** (0, 1, 2, 3, 4, etc.)
6. **Codes must be unique** across all questions
7. **Position values start at 0** and increment sequentially

## Example Complete Output

Generate questions for autism assessment domains. Here's what a complete file should look like:

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

## Your Task

When I provide a request, generate a complete, valid JSON file following this format. Include:

1. Domain information with appropriate key, label, and description
2. Multiple questions (5-10 questions per domain recommended)
3. Mix of response types (scale, multi_choice, and text questions)
4. Proper question codes following the naming convention
5. Appropriate options for scale and multi_choice questions
6. Valid JSON syntax (use double quotes, proper commas, etc.)

Return ONLY the JSON, no explanations or markdown formatting around it (unless I ask for it).

---

## Example Prompts You Can Use

### Single Domain
"Generate 8 communication assessment questions in the JSON format above. Include 5 scale questions (0-4), 2 text questions, and 1 multi-choice question. Domain key: 'communication'."

### Multiple Domains
"Generate questions for a complete autism assessment with these domains: communication, social, sensory, flexibility, emotional_regulation. Include 5-7 questions per domain with a mix of scale (0-4), multi-choice, and text questions. Use the multi-domain JSON format."

### Specific Age Group
"Generate 10 communication questions for preschool-aged children (ages 3-5) using the JSON format. Focus on basic communication skills with appropriate wording for young children. Include 6 scale questions, 2 text questions, and 2 multi-choice questions."

---

**Ready to generate? Provide your requirements and I'll create the JSON file!**

