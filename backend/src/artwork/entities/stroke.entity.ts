export type StrokeEntity = {
   pointList: Point[]; // List of coordinates [x,y]
   color: number;
   brushSize: number;
}

type Point = [number, number];