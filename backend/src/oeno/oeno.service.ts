import { HttpException, Injectable } from "@nestjs/common";
import OpenAI from "openai";

import { oenoPromptDto } from "./dto/oenoPrompt.dto";
import { promptBreakerContext } from "./contexts/promptBreaker.context";
import { breakPromptTool } from "./tools/breakPrompt.tool";

@Injectable()
export class OenoService {
   private openAI: OpenAI;

   constructor() {
      this.openAI = new OpenAI({
         apiKey: process.env.OPENAI_API_KEY,
      });
   }

   async breakPrompt({prompt}: oenoPromptDto) {

      // creating AI prompt
      const updatedChat = [
         {role: "system" as const, content: promptBreakerContext},
         {role: "user" as const, content: prompt}
      ];

      // creating break_prompt tool for the ai
      const tools = [
         {
            type: "function" as const,
            function: breakPromptTool(3),
         }
      ];

      // send context and prompt to the AI
      let parsedResponse;
      try {
         const response = await this.openAI.chat.completions.create({
            model: "gpt-4o-mini",
            messages: updatedChat,
            tools:tools
         });

         // get the actual contents of the response from openAI
         const choice = response.choices[0];
         if (choice.finish_reason != "tool_calls") { throw new Error("OpenAI did not respond with a tool_call"); }
         
         // attempt to parse the data returned
         const toolCall = choice.message.tool_calls?.[0];
         if (toolCall?.type !== 'function') { throw new Error("OpenAI did not respond with an expected tool_call"); }
         const argumentString = toolCall.function.arguments || '';
         parsedResponse = JSON.parse(argumentString);
         if (!parsedResponse){ throw new Error("Failed to parse the response from OpenAI"); }
      }
      catch(error){
         console.error("\x1b[31m[OenoService] server failed to get a valid broken prompt response from openAI\x1b[0m\n", error);
         throw new HttpException("Internal server error", 500);
      }

      const result = parsedResponse.prompts.map((prompt) => { return `${prompt.subject} - ${prompt.action}` });

      return result;
   }

}