export type ImageEntity = {
   path: string,
   url: string,
   size?: number | null,
   orig_name?: string | null,
   mime_type?: string | null,
   is_stream: boolean,
   meta: Record<string, unknown>,
}