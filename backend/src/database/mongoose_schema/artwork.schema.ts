import { Prop, Schema, SchemaFactory, Virtual } from "@nestjs/mongoose";
import { HydratedDocument } from "mongoose";

@Schema ({ timestamps: true })
export class Artwork {
   @Virtual()
   id: string;

   @Prop({ required: true })
   title: string;

   @Prop({ required: true })
   prompt: string;

   @Prop({ type: [Object], default: [] })
   stencilList: {
      prompt: string;
      preferredImageIndex: number;
      imageList: {
         path: string;
         url: string;
         size?: number;
         orig_name?: string;
         mime_type?: string;
         is_stream: boolean;
         meta: any;
      }[];
      position?: number[]; // Coordinates [x,y]
      rotation?: number;
      scale?: number;
   }[];

   @Prop({ type: [Object], default: [] })
   strokeList: {
      pointList: [][];
      color: number;
      brushSize: number;
   }[]

   @Prop({ type: Date, default: Date.now })
   updatedAt: Date;
}

export type ArtworkDocument = HydratedDocument<Artwork>;
export const ArtworkSchema = SchemaFactory.createForClass(Artwork);

// set returned values from mongoDB to use id instead of _id (for uniformity with postgres)
ArtworkSchema.virtual('id').get(function(){
   return this._id.toHexString();
});

ArtworkSchema.set('toJSON', { virtuals: true });
ArtworkSchema.set('toObject', { virtuals: true });