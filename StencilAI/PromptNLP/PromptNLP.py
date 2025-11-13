import spacy

# Load spaCy English model (make sure you have installed `en_core_web_sm` or another model)
nlp = spacy.load("en_core_web_sm")

def decompose_prompt(prompt: str):
    doc = nlp(prompt)
    # 1. Extract noun phrases
    noun_phrases = []
    for chunk in doc.noun_chunks:
        text = chunk.text.strip()
        noun_phrases.append((chunk, text))
    # Deduplicate by text
    seen = set()
    np_texts = []
    for chunk, text in noun_phrases:
        if text.lower() not in seen:
            seen.add(text.lower())
            np_texts.append((chunk, text))
    # 2. Independent prompts: “a X” (or preserve existing article)
    independent_prompts = []
    for chunk, text in np_texts:
        # If it already has “a” or “the” at start, keep; else prefix “a”
        words = text.split()
        if words[0].lower() in ("a", "an", "the"):
            independent_prompts.append(text)
        else:
            independent_prompts.append("a " + text)
    # 3. Relation prompts: e.g., NP1 (prep) NP2
    relation_prompts = []
    for token in doc:
        # Look for prepositional dependency linking NP objects
        # e.g., token.dep_ == "prep" and its head is a noun, and there is a pobj child that is a noun
        if token.dep_ == "prep" and token.head.pos_ == "NOUN":
            # find pobj (object of preposition)
            for child in token.children:
                if child.dep_ == "pobj" and child.pos_ == "NOUN":
                    np1 = token.head.text
                    prep = token.text
                    np2 = child.text
                    # Build prompt like “a NP1 [prep] a NP2”
                    rel_prompt = f"a {np1} {prep} a {np2}"
                    relation_prompts.append(rel_prompt)
    # 4. Combine results
    all_prompts = independent_prompts.copy()
    # avoid duplicates
    for rp in relation_prompts:
        if rp not in all_prompts:
            all_prompts.append(rp)
    return all_prompts

# Example usage:
for example in [
    "a ball in a car",
    "a brown dog with a red ball in a car at night",
    "two cats on the sofa under a lamp"
]:
    print("Prompt:", example)
    outputs = decompose_prompt(example)
    print(" → Sub-prompts:", outputs)
    print()
