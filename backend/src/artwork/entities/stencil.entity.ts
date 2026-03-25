import { ImageEntity } from "src/oeno/entities/image.entity";

export type StencilEntity = {
   prompt: string;
   preferredImageIndex: number;
   imageList: ImageEntity[];
   position?: Point; // Coordinates [x,y]
   rotation?: number;
   scale?: number;
}

type Point = [number, number];