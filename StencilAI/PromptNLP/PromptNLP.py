"""
PromptNLP - Decompose complex image generation prompts into sub-prompts

This module uses spaCy NLP to break down complex text prompts into smaller,
atomic sub-prompts representing individual objects and their relationships.
Useful for hierarchical image generation workflows where objects need to be
generated separately before composition.

Author: StencilAI
License: MIT
"""

import spacy
from typing import List

# Load spaCy's English language model for NLP processing
nlp = spacy.load("en_core_web_sm")


def clean_np(chunk) -> str:
    """
    Clean and normalize a noun phrase chunk.

    Args:
        chunk: spaCy Span object representing a noun phrase

    Returns:
        str: Cleaned text with leading/trailing whitespace removed
    """
    text = chunk.text.strip()
    return text


def make_independent_prompt(text: str) -> str:
    """
    Convert a noun phrase into a standalone prompt with proper article usage.

    Applies grammatical rules to ensure the prompt is self-contained:
    - Adds "a" article for singular nouns without articles
    - Preserves plural forms (e.g., "cats")
    - Preserves numerals (e.g., "two dogs")
    - Preserves existing articles (e.g., "the ball")

    Args:
        text: Noun phrase text to convert

    Returns:
        str: Grammatically correct standalone prompt

    Examples:
        >>> make_independent_prompt("dog")
        'a dog'
        >>> make_independent_prompt("cats")
        'cats'
        >>> make_independent_prompt("two dogs")
        'two dogs'
    """
    words = text.split()

    # Preserve prompts starting with numerals or "the" article
    if words[0].isdigit() or (len(words) > 1 and words[0].lower() == 'the'):
        return text

    # Preserve plural nouns (simple heuristic: ends with 's')
    if words[-1].endswith('s'):
        return text

    # Add indefinite article for singular nouns
    return "a " + text


def decompose_prompt(prompt: str, keep_modifiers: bool = False,
                     include_background: bool = False) -> List[str]:
    """
    Decompose a complex prompt into atomic sub-prompts.

    Uses spaCy NLP to extract:
    1. Individual noun phrases (objects)
    2. Relational phrases (object-preposition-object)

    The function filters duplicates and optionally removes modifiers
    and background elements to focus on core objects.

    Args:
        prompt: Input text prompt to decompose
        keep_modifiers: If False, extracts only head nouns (e.g., "dog" from "brown dog")
        include_background: If False, filters out temporal/environmental nouns
                          (e.g., "night", "morning")

    Returns:
        List[str]: List of atomic sub-prompts

    Examples:
        >>> decompose_prompt("a ball in a car")
        ['a ball', 'a car', 'a ball in a car']

        >>> decompose_prompt("a brown dog with a red ball")
        ['a dog', 'a ball', 'a dog with a ball']
    """
    doc = nlp(prompt)

    # Step 1: Extract and clean all noun phrases
    np_chunks = list(doc.noun_chunks)
    np_texts = []
    for chunk in np_chunks:
        text = clean_np(chunk)
        np_texts.append((chunk, text))

    # Step 2: Deduplicate noun phrases (case-insensitive)
    seen = set()
    unique_nps = []
    for chunk, text in np_texts:
        key = text.lower()
        if key not in seen:
            seen.add(key)
            unique_nps.append((chunk, text))

    # Step 3: Generate independent prompts for each noun phrase
    independent = []
    for chunk, text in unique_nps:
        if not keep_modifiers:
            # Extract only the head noun (removes adjectives/modifiers)
            head = chunk.root
            text = head.text

        prompt_text = make_independent_prompt(text)
        independent.append(prompt_text)

    # Step 4: Extract relational prompts (noun-preposition-noun patterns)
    # Example: "dog with ball" from "a dog with a ball in a car"
    relations = []
    for token in doc:
        # Look for prepositions attached to nouns
        if token.dep_ == "prep" and token.head.pos_ == "NOUN":
            for child in token.children:
                # Find the object of the preposition
                if child.dep_ == "pobj" and child.pos_ == "NOUN":
                    np1 = token.head.text  # First noun (subject)
                    prep = token.text       # Preposition (with, in, on, etc.)
                    np2 = child.text        # Second noun (object)

                    # Construct relational prompt
                    rel = f"{make_independent_prompt(np1)} {prep} {make_independent_prompt(np2)}"
                    relations.append(rel)

    # Step 5: Combine independent and relational prompts
    all_prompts = list(independent)
    for rel in relations:
        if rel not in all_prompts:  # Avoid duplicates
            all_prompts.append(rel)

    # Step 6: Optionally filter background/temporal elements
    if not include_background:
        filtered = [p for p in all_prompts if not is_background_prompt(p)]
    else:
        filtered = all_prompts

    return filtered


def is_background_prompt(prompt_text: str) -> bool:
    """
    Determine if a prompt represents a background or temporal element.

    Uses heuristics to identify prompts that describe scene context
    rather than concrete objects (e.g., "at night", "in the morning").

    Args:
        prompt_text: Prompt text to evaluate

    Returns:
        bool: True if prompt is likely a background element

    Examples:
        >>> is_background_prompt("a night")
        True
        >>> is_background_prompt("a dog")
        False
        >>> is_background_prompt("a lamp")
        False
    """
    # Temporal/environmental nouns to filter
    bg_nouns = {"night", "day", "evening", "morning"}

    words = prompt_text.split()

    # Check for simple temporal phrases: "a/the [time-of-day]"
    if len(words) == 2 and words[0].lower() in ("a", "the") and words[1].lower() in bg_nouns:
        return True

    return False

def main():
    """
    Demonstration of prompt decomposition functionality.

    Runs several example prompts through the decomposition process
    to showcase the extraction of individual objects and relationships.
    """
    print("=" * 60)
    print("PromptNLP - Prompt Decomposition Examples")
    print("=" * 60)
    print()

    # Test cases with varying complexity
    examples = [
        "a ball in a car",
        "a brown dog with a red ball in a car at night",
        "two cats on the sofa under a lamp"
    ]

    for example in examples:
        print(f"Prompt: {example}")
        sub_prompts = decompose_prompt(
            example,
            keep_modifiers=False,
            include_background=False
        )
        print(f" → Sub-prompts: {sub_prompts}")
        print()


if __name__ == "__main__":
    main()
