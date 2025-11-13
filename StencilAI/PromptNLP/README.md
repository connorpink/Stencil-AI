# PromptNLP

A Natural Language Processing tool that decomposes complex image generation prompts into atomic sub-prompts representing individual objects and their spatial relationships.

## Overview

PromptNLP uses spaCy's NLP capabilities to break down complex text prompts into smaller, manageable components. This is particularly useful for hierarchical image generation workflows where individual objects need to be generated separately before being composed into a final scene.

## How It Works

The decomposition process follows these steps:

### 1. **Noun Phrase Extraction**
Uses spaCy to identify all noun phrases in the input prompt (e.g., "a brown dog", "a red ball").

### 2. **Deduplication**
Removes duplicate noun phrases using case-insensitive matching to ensure unique objects.

### 3. **Independent Prompt Generation**
Creates standalone prompts for each object by:
- Extracting head nouns (removing modifiers like colors/adjectives)
- Adding proper articles ("a", "the") or preserving plurals
- Example: "brown dog" → "a dog"

### 4. **Relational Extraction**
Identifies spatial relationships using dependency parsing:
- Detects noun-preposition-noun patterns
- Examples: "dog with ball", "cats on sofa", "ball in car"

### 5. **Background Filtering**
Optionally removes temporal/environmental elements:
- Filters out: "night", "day", "evening", "morning"
- Retains: concrete objects like "lamp", "car", "dog"

### 6. **Combination**
Merges independent prompts and relational prompts while avoiding duplicates.

## Usage

```python
from PromptNLP import decompose_prompt

# Basic usage
prompt = "a brown dog with a red ball in a car at night"
sub_prompts = decompose_prompt(prompt, keep_modifiers=False, include_background=False)

print(sub_prompts)
# Output: ['a dog', 'a ball', 'a car', 'a dog with a ball', 'a dog in a car']
```

### Parameters

- **`prompt`** (str): The input text prompt to decompose
- **`keep_modifiers`** (bool, default=False):
  - `False`: Extract only head nouns ("brown dog" → "dog")
  - `True`: Keep full noun phrases ("brown dog" → "brown dog")
- **`include_background`** (bool, default=False):
  - `False`: Filter out temporal/environmental nouns
  - `True`: Keep all extracted prompts

### Running Examples

```bash
python PromptNLP.py
```

## Test Results

### Example 1: Simple Spatial Relationship
```
Prompt: a ball in a car
→ Sub-prompts: ['a ball', 'a car', 'a ball in a car']
```

**Analysis:**
- Extracts 2 individual objects: ball, car
- Captures 1 spatial relationship: ball-in-car
- Total: 3 sub-prompts

---

### Example 2: Complex Multi-Object Scene
```
Prompt: a brown dog with a red ball in a car at night
→ Sub-prompts: ['a dog', 'a ball', 'a car', 'a dog with a ball', 'a dog in a car']
```

**Analysis:**
- Extracts 3 individual objects: dog, ball, car
- Removes modifiers: "brown" and "red" filtered out
- Captures 2 relationships: dog-with-ball, dog-in-car
- Filters background element: "at night" removed
- Total: 5 sub-prompts

---

### Example 3: Multiple Objects with Spatial Hierarchy
```
Prompt: two cats on the sofa under a lamp
→ Sub-prompts: ['cats', 'a sofa', 'a lamp', 'cats on a sofa', 'cats under a lamp']
```

**Analysis:**
- Extracts 3 objects: cats (plural preserved), sofa, lamp
- Preserves quantity: "two cats" → "cats"
- Captures 2 spatial relationships: cats-on-sofa, cats-under-lamp
- Total: 5 sub-prompts

---

## Architecture

```
Input Prompt
    ↓
spaCy NLP Processing
    ↓
Noun Phrase Extraction → Deduplication → Head Noun Extraction
    ↓
Dependency Parsing → Relational Pattern Matching
    ↓
Background Filtering
    ↓
Sub-Prompt List
```

## Dependencies

- **spaCy** >= 3.0
- **en_core_web_sm** (spaCy English language model)

### Installation

```bash
pip install spacy
python -m spacy download en_core_web_sm
```
>Or use the [requirements file](../requirements.txt) with UV to setup all dependencies.

## Use Cases

1. **Hierarchical Image Generation**: Generate individual objects before composing scenes
2. **Prompt Augmentation**: Create variations by recombining sub-prompts
3. **Object Detection Training**: Extract object labels from natural language descriptions
4. **Semantic Search**: Index images by decomposed object components
5. **Stencil Generation**: Create separate stencils for each object in a scene

## Limitations

- Simple plural detection (heuristic: words ending in 's')
- Background filtering limited to predefined time-of-day nouns
- No support for complex grammatical structures (e.g., nested clauses)
- Preposition handling limited to direct noun-prep-noun patterns
