import { Prop, Schema, SchemaFactory } from "@nestjs/mongoose";
import { Document } from "mongoose";


@Schema ({ timestamps: true })
export class Artwork extends Document {
   @Prop({ required: true })
   title: string;

   @Prop({ required: true })
   prompt: string;

   @Prop({ type: [Object], default: [] })
   stencilList: {
      prompt: string;
      imageList: {
         path: string;
         url: string;
         size?: number;
         orig_name?: string;
         mime_type?: string;
         is_stream: boolean;
         meta: any;
      }[];
   }[];

   @Prop({ type: [Object], default: [] })
   strokeList: {
      points: {
         dx: number;
         dy: number;
      }[];
      color: number;
      brushSize: number;
   }
}

export const ArtworkSchema = SchemaFactory.createForClass(Artwork);

// set returned values from mongoDB to use id instead of _id (for uniformity with postgres)
ArtworkSchema.set('toJSON', {
   virtuals: true,
   versionKey: false,
   transform: function (doc, ret: any) {
      ret.id = ret._id;
      delete ret._id;
   },
});

ArtworkSchema.set('toObject', {
   virtuals: true,
   versionKey: false,
   transform: function (doc, ret: any) {
      ret.id = ret._id;
      delete ret._id;
   }
});