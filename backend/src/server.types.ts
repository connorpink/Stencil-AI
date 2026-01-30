export type ImageDto = {
   path: string,
   url: string,
   size?: number | null,
   orig_name?: string | null,
   mime_type?: string | null,
   is_stream: boolean,
   meta: any
}

export type UserDto = {
   id: number
   username: string
   email?: string
}

// artwork dto start
export type ArtworkDto = {
   id: string;
   title: string;
   prompt: string;
   stencilList: StencilDto[];
   strokeList: StrokeDto[];
   updatedAt: Date;
}

export type StencilDto = {
   prompt: string;
   preferredImageIndex: number;
   imageList: ImageDto[];
   position?: number[]; // Coordinates [x,y]
   rotation?: number;
   scale?: number;
}

type StrokeDto = {
   pointList: number[][]; // List of coordinates [x,y]
   color: number;
   brushSize: number;
}
// artwork dto end