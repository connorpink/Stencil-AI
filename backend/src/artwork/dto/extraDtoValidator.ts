import { registerDecorator, ValidationOptions } from "class-validator";

export function IsPointTuple(validationOptions?: ValidationOptions) {
   return function (object: Object, propertyName: string) {
      registerDecorator({
         name: 'isPointTuple',
         target: object.constructor,
         propertyName,
         options: validationOptions,
         validator: {
            validate(value: any) {
               return (
                  Array.isArray(value) &&
                  value.length === 2 &&
                  typeof value[0] === 'number' &&
                  typeof value[1] === 'number'
               );
            },
         },
      });
   };
}