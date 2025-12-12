import { HttpException, Injectable } from "@nestjs/common";
import OpenAI from "openai";
import { firstValueFrom } from "rxjs";

import { promptBreakerContext } from "./contexts/promptBreaker.context";
import { breakPromptTool } from "./tools/breakPrompt.tool";
import { ImageDto, StencilDto } from "src/server.types";
import { HttpService } from "@nestjs/axios";
import { OenoImageDto } from "./oeno.types";
import { VolumeService } from "src/volume/volume.service";

@Injectable()
export class OenoService {
   private openAI: OpenAI;
   private gradioClient: any = null;
   private readonly huggingFaceName: string = 'mrpink925/StencilAI_Demo';
   private readonly httpService: HttpService;
   private readonly volumeService: VolumeService;

   constructor () {
      this.openAI = new OpenAI({
         apiKey: process.env.OPENAI_API_KEY,
      });
      this.httpService = new HttpService();
      this.volumeService = new VolumeService();
   }

   async onModuleInit() {
      await this.initializeGradioClient()
   }

   private async initializeGradioClient() {
      try {
         const { Client } = await import("@gradio/client");
         this.gradioClient = await Client.connect(this.huggingFaceName);
         console.log("\x1b[32m[OenoService] Connected to Gradio Space\x1b[0m");
      }
      catch (error) {
         console.error("\x1b[31m[OenoService] Failed to connect to Gradio Space\x1b[0m", error);
         throw error;
      }
   }

   async breakPrompt(prompt: string, subPromptCount: number) {

      // creating AI prompt
      const updatedChat = [
         {role: "system" as const, content: promptBreakerContext},
         {role: "user" as const, content: prompt}
      ];

      // creating break_prompt tool for the ai
      const tools = [{
         type: "function" as const,
         function: breakPromptTool(subPromptCount),
      }];

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

      const result: string[] = parsedResponse.prompts.map((prompt) => { return `${prompt.subject} - ${prompt.action}` });

      return result;
   }

   async generateStencil(prompt: string): Promise<StencilDto> {

      // prep the payload for the oeno api call
      const payload = {
         prompt: prompt,
         model_type: "Checkpoint-1000",
         negative_prompt: "",
         num_images: 4,
         num_inference_steps: 25,
         guidance_scale: 7.5,
         width: 512,
         height: 512,
         seed: 42,
         use_seed: true,
         add_stencil_suffix: true,
         clean_background: true,
      }

      let oenoImageList: OenoImageDto[];
      try {
         // generate images using oeno
         const result = await this.gradioClient.predict("/generate_stencil", payload);
         const [oenoResponse, status] = result.data as [OenoImageDto[], string];
         oenoImageList = oenoResponse;
      }
      catch (error) {
         throw new Error("\x1b[31m[OenoService] server failed to collect stencils form Oeno\x1b[0m\n" + error)
      }

      // make sure images were received
      if (!oenoImageList || oenoImageList.length === 0) { throw new Error("No images returned from Oeno API"); }

      // normalize and download each image from oenoImageList
      let imageList: ImageDto[];
      try {
         imageList = await Promise.all(oenoImageList.map(
            async (oenoImage: OenoImageDto) => {
               // get the image content from the oeno response
               let image: ImageDto = oenoImage.image;

               const response = await firstValueFrom(
                  this.httpService.get(image.url, {
                     responseType: 'arraybuffer',
                  }),
               );
               
               // verify the expected file type was returned
               const contentType = response.headers['content-type'];
               if (contentType !== 'image/webp') { throw new Error(`Expected images/webp content type but got ${contentType}`); }

               // send the image over to volume service for saving
               const buffer = Buffer.from(response.data);
               const fileName = `oenoImage-${Date.now()}.webp`;
               this.volumeService.saveImage(buffer, 'stencil', fileName);

               // redefine the path and url to where it is saved in the server
               image.path = "stencil/" + fileName;
               image.url = "server/" + image.path;

               return image;
            }
         ));
      }
      catch (error) {
         throw new Error("\x1b[31m[OenoService] server failed to download images provide by oeno\x1b[0m\n" + error)
      }

      return {
         prompt: prompt,
         imageList: imageList,
      };
   }
}