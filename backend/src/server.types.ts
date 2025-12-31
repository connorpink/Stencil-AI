export type ImageDto = {
   path: string,
   url: string,
   size?: number,
   orig_name?: string,
   mime_type?: string,
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
   imageList: ImageDto[];
}

type StrokeDto = {
   points: OffsetDto[];
   color: number;
   brushSize: number;
}

type OffsetDto = {
   dx: number;
   dy: number;
}
// artwork dto end