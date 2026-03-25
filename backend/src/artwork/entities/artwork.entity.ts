import { StencilEntity } from "./stencil.entity";
import { StrokeEntity } from "./stroke.entity";

export type ArtworkEntity = {
   id: string;
   ownerId: number;
   title: string;
   prompt: string;
   stencilList: StencilEntity[];
   strokeList: StrokeEntity[];
   updatedAt: Date;
}