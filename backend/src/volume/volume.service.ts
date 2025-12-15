import * as fs from 'fs';
import { HttpException, Injectable } from "@nestjs/common";
import path, { resolve } from "path";
import { Response } from 'express';

@Injectable()
export class VolumeService {
   private readonly volumeDirectory = path.resolve(process.cwd(), 'volume');
   private readonly buckets = {
      stencil: 'stencil',
   }
   private readonly allowedExtensions = new Set(['.png', '.jpg', '.jpeg', '.webp']);
   private readonly tempFileMaxAge = 1000 * 60 * 60; // 1 hour
   private readonly garbageCollectionInterval = 1000 * 60 * 60 * 24; // 24 hours
   
   constructor () {
      this.verifyVolumeLayout();
   }

   onModuleInit() {
      // Schedule periodic temp folder cleanup
      setInterval(() => this.cleanupTempFiles(), this.garbageCollectionInterval);
   }

   // verify the setup of the Volume folder (on startup)
   private verifyVolumeLayout() {
      // make sure the volume root itself is setup correctly
      if (!fs.existsSync(this.volumeDirectory)) { throw new Error(`Volume root not found: ${this.volumeDirectory}`); }
      const volumeDirectoryStatus = fs.lstatSync(this.volumeDirectory);
      if (volumeDirectoryStatus.isSymbolicLink()) { throw new Error(`Volume root must not be a symbolic link: ${this.volumeDirectory}`); }
      if (!volumeDirectoryStatus.isDirectory()) { throw new Error(`Volume root is not a directory: ${this.volumeDirectory}`); }

      // helper function for making sure a subdirectory exists, is valid, and is usable
      const verifyValidFolder = (subdirectory: string) => {
         // Basic sanity on the configured subdirectory path
         if (path.isAbsolute(subdirectory) || subdirectory.split(/[\\/]+/).some(directory => !directory || directory === "." || directory === "..")) { throw new Error(`Invalid bucket path for "${subdirectory}": ${subdirectory}`); }

         // verify the integrity of any subdirectory that don't exist at root level
         const parts = subdirectory.split(/[\\/]+/).filter(Boolean);
         let walk = this.volumeDirectory;
         for (const folder of parts.slice(0, -1)) {
            walk = path.join(walk, folder);
            if (fs.existsSync(walk)) {
               const status = fs.lstatSync(walk);
               if (!status.isDirectory()) { throw new Error(`Non-directory path segment in bucket path: ${walk}`); }
               if (status.isSymbolicLink()) { throw new Error(`Symlink not allowed in bucket path: ${walk}`); }
            }
            else {
               // create directory if it does not exist
               fs.mkdirSync(walk, { recursive: true, mode: 0o755 });
            }
         }

         const directory = path.resolve(this.volumeDirectory, subdirectory);

         // Make sure subdirectory exists, if not then attempt to create it
         if (!fs.existsSync(directory)) { fs.mkdirSync(directory, { recursive: true, mode: 0o755 }); }

         // Make sure subdirectory is a valid directory type
         const bucketStatus = fs.lstatSync(directory);
         if (!bucketStatus.isDirectory()) { throw new Error(`Subdirectory "${subdirectory}" is not a directory: ${directory}`); }
         if (bucketStatus.isSymbolicLink()) { throw new Error(`Subdirectory "${subdirectory}" must not be a symlink: ${directory}`); }

         // Prevent traversal or symlink escape
         const normalizedBucket = fs.realpathSync.native(directory);
         if (!normalizedBucket.startsWith(this.volumeDirectory + path.sep) && normalizedBucket !== this.volumeDirectory) { 
            throw new Error(`Subdirectory "${subdirectory}" escapes volume root`); 
         }

         // Make sure volume.service has read + write access to the subdirectory
         try { fs.accessSync(directory, fs.constants.R_OK ); } 
         catch { throw new Error(`volume.service does not have read access to ${directory}`); }
         try { fs.accessSync(directory, fs.constants.W_OK); } 
         catch { throw new Error(`volume.service does not have write access to ${directory}`); }
      }

      for (const key of Object.keys(this.buckets)) { 
         verifyValidFolder(this.buckets[key]);
      }
      verifyValidFolder("temp");
   }

   // garbage collection for the temp folder
   private async cleanupTempFiles() {
      const tempDir = this.getTempFolder();
      
      try {
         const files = await fs.promises.readdir(tempDir);
         const now = Date.now();

         for (const file of files) {
            const filePath = path.join(tempDir, file);
            
            try {
               const stats = await fs.promises.stat(filePath);
               
               // Check if file is older than max age
               const fileAge = now - stats.mtimeMs;
               if (fileAge > this.tempFileMaxAge) {
                  await fs.promises.unlink(filePath);
                  console.log(`Cleaned up stale temp file: ${file} (age: ${Math.round(fileAge / 60000)}min)`);
               }
            } catch (error) {
               console.error(`Error processing temp file ${file}:`, error.message);
            }
         }
      } catch (error) {
         console.error('Failed to run temp cleanup:', error);
      }
   }

   // find the absolute path for a bucket key, ensuring it's valid
   private findSubdirectory(bucketKey: string) {
      const subdirectory = this.buckets[bucketKey];
      if (!subdirectory) { throw new Error(`Invalid bucket: ${bucketKey}`); }

      //ensure the path is valid (no unexpected escapes)
      const basePath = path.resolve(this.volumeDirectory);
      const absolutePath = path.resolve(basePath, subdirectory);
      if (!absolutePath.startsWith(basePath + path.sep) && absolutePath !== basePath) { 
         throw new Error("Bucket has been modified to allow an escape, unable to use bucket"); 
      }
      return absolutePath;
   }

   // temp path should be grabbed from here (in case of file path changes)
   private getTempFolder() {
      return path.resolve(this.volumeDirectory, "temp");
   }

   // basic file signature check to make sure an expected file type is being uploaded
   private fileFilter(buffer: Buffer) {
      // Check file signatures in the buffer
      const png = buffer[0] === 0x89 && buffer[1] === 0x50 && buffer[2] === 0x4E && buffer[3] === 0x47;
      const jpg = buffer[0] === 0xFF && buffer[1] === 0xD8 && buffer[2] === 0xFF;
      const webp = buffer[8] === 0x57 && buffer[9] === 0x45 && buffer[10] === 0x42 && buffer[11] === 0x50;

      if (!(png || jpg || webp)) {
         throw new Error ("invalid file signature given to fileFilter");
      }
      else {
         return png || jpg || webp;
      }
   }

   // Run the file through an antivirus software
   private isFileClean(_: any) {
      // setup with docker before deployment
      return true;
   }

   // check for possible issues with the file basename
   private checkSafeBasename(name) {
      if (
         typeof name !== "string"
         || name.length === 0
         || name.length > 255
         || path.basename(name) !== name // Make sure there are no path separators (/, \) or other path-related issues
         || name.includes("..") || !/^[A-Za-z0-9._-]+$/.test(name) // Make sure there are no suspicious patterns
         || !this.allowedExtensions.has(path.extname(name).toLowerCase()) // Make sure the expected file type is being uploaded
      ) { 
         throw new Error ("file basename was rejected"); 
      }
      else { 
         return true; 
      }
   }

   // save an image by passing it as the contents of a buffer
   async saveImage(image: Buffer, bucketKey: string, fileName: string) {
      this.checkSafeBasename(fileName);
      this.fileFilter(image);
      const tempDirectory = this.getTempFolder();
      const finalDirectory = this.findSubdirectory(bucketKey);

      const tempPath = path.join(tempDirectory, fileName);
      const finalPath = path.join(finalDirectory, fileName);

      // Write image to temp
      fs.writeFileSync(tempPath, image);

      // Scan file
      const clean = await this.isFileClean(tempPath);
      if (!clean) {
         try { fs.unlinkSync(tempPath); }
         catch { console.error("Infected file found, unable to remove from temp folder:" + tempPath); }
         throw new Error('Upload blocked: antivirus detected malware');
      }

      // Move to final bucket
      fs.renameSync(tempPath, finalPath);
   }

   async getImage(bucket: string, fileName: string, response: Response) {
      this.checkSafeBasename(fileName);
      const directoryPath = this.findSubdirectory(bucket);
      const filePath = path.join(directoryPath, fileName);

      // make sure file exists and return it
      if (!fs.existsSync(filePath)) { throw new HttpException('file being referenced not found', 404)}
      return response.sendFile(filePath);
   }

   async deleteImage(filePath:string) {
      const splitPath = filePath.split("/");
      if (splitPath.length != 2) { throw new Error ("invalid path sent to VolumeService.deleteImage: path must look like {bucket}/{base name}\n" + "Path provided: " + filePath); }
      this.checkSafeBasename(splitPath[1]);

      const directory = this.findSubdirectory(splitPath[0]);
      const completePath = path.join(directory, splitPath[1]);
      try {
         fs.unlinkSync(completePath);
      }
      catch (error) {
         console.log("Failed to delete file from volume: " + completePath);
         throw error;
      }
   }
}