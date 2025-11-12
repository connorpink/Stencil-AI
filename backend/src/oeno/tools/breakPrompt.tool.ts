
export function breakPromptTool(totalSubPrompts: number = 3){

   return {
      name: "break_prompt",
      description: `Produce exactly ${totalSubPrompts} independent, context-free sub-prompts.`
         + " Each sub-prompt must be drawable on its own and must NOT reference other entities, props, locations, or relationships."
         + " Keep language generic. Avoid prepositional phrases and objects (no 'with/at/on/next to/near')."
         + " Format: a short subject plus a short action phrase.",
      parameters: {
         type: "object",
         properties: {
            prompts: {
               type: "array",
               items: subPrompt(),
               minItems: totalSubPrompts,
               maxItems: totalSubPrompts,
               description: `Array of ${totalSubPrompts} sub-prompts`
            }
         },
         required: ["prompts"],
         additionalProperties: false
      }
   }
}

function subPrompt() {
   return {
      type: "object",
      properties: {
         subject: {
            type: "string",
            description: "A very short subject (1-2 words max)"
         },
         action: {
            type: "string",
            description: "A concise action phrase describing what the subject is doing (1-5 words max)"
         }
      },
      required: ["subject", "action"],
      additionalProperties: false,
   }
}