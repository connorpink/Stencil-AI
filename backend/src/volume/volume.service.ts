import * as fs from 'fs';
import { Injectable } from "@nestjs/common";
import path from "path";

@Injectable()
export class VolumeService {
   private readonly volumeDirectory = path.resolve(process.cwd(), 'volume');
   private readonly buckets = {
      stencil: 'stencil',
      temp: 'temp',
   }
   private readonly allowedExtensions = new Set(['.png', '.jpg', '.jpeg', '.webp', '.bin']);
   
   constructor () {
      this.verifyVolumeLayout();
   }

   // verify the setup of the Volume folder (on startup)
   private verifyVolumeLayout() {
      // make sure the volume root itself is setup correctly
      if (!fs.existsSync(this.volumeDirectory)) { throw new Error(`Volume root not found: ${this.volumeDirectory}`); }
      const volumeDirectoryStatus = fs.lstatSync(this.volumeDirectory);
      if (volumeDirectoryStatus.isSymbolicLink()) { throw new Error(`Volume root must not be a symbolic link: ${this.volumeDirectory}`); }
      if (!volumeDirectoryStatus.isDirectory()) { throw new Error(`Volume root is not a directory: ${this.volumeDirectory}`); }

      // get the real path of the volume directory (remove any ../ from the path)
      const realVolumeDirectory = fs.realpathSync.native(this.volumeDirectory);

      // helper function for making sure a folder exists, is valid, and is usable
      function verifyValidFolder(subdirectory: string) {
         // Basic sanity on the configured bucket path
         if (path.isAbsolute(subdirectory) || subdirectory.split(/[\\/]+/).some(directory => !directory || directory === "." || directory === "..")) { throw new Error(`Invalid bucket path for "${subdirectory}": ${subdirectory}`); }

         // verify the integrity of buckets that don't exist directly in the root of volume
         const parts = subdirectory.split(/[\\/]+/).filter(Boolean);
         let walk = realVolumeDirectory;
         for (const folder of parts.slice(0, -1)) {
            walk = path.join(walk, folder);
            if (fs.existsSync(walk)) {
               const status = fs.lstatSync(walk);
               if (status.isSymbolicLink()) { throw new Error(`Symlink not allowed in bucket path: ${walk}`); }
               if (!status.isDirectory()) { throw new Error(`Non-directory path segment in bucket path: ${walk}`); }
            }
         }

         const directory = path.resolve(realVolumeDirectory, subdirectory);

         // Make sure bucket exists
         if (!fs.existsSync(directory)) { fs.mkdirSync(directory, { recursive: true, mode: 0o755 }); }

         // Make sure bucket is a valid directory
         const bucketStatus = fs.lstatSync(directory);
         if (!bucketStatus.isDirectory()) { throw new Error(`Subdirectory "${subdirectory}" is not a directory: ${directory}`); }
         if (bucketStatus.isSymbolicLink()) { throw new Error(`Subdirectory "${subdirectory}" must not be a symlink: ${directory}`); }

         // Prevent traversal or symlink escape
         const normalizedBucket = fs.realpathSync.native(directory);
         if (!normalizedBucket.startsWith(realVolumeDirectory + path.sep) && normalizedBucket !== realVolumeDirectory) { throw new Error(`Subdirectory "${subdirectory}" escapes volume root`); }

         // Make sure bucket is writable
         try { fs.accessSync(directory, fs.constants.W_OK); } 
         catch { throw new Error(`Bucket "${subdirectory}" not writable: ${directory}`); }
      }

      for (const key of Object.keys(this.buckets)) { 
         verifyValidFolder(this.buckets[key]);
      }
   }

   // find the absolute path for a bucket key, ensuring it's valid
   private findSubdirectory(bucketKey: string) {
      const subdirectory = this.buckets[bucketKey];
      if (!subdirectory) { throw new Error(`Invalid bucket: ${bucketKey}`); }

      //ensure the path is valid
      const basePath = path.resolve(this.volumeDirectory);
      const absolutePath = path.resolve(basePath, subdirectory);
      if (!absolutePath.startsWith(basePath + path.sep) && absolutePath !== basePath) { throw new Error("Invalid upload folder."); }
      return absolutePath;
   }

   private fileFilter(buffer: Buffer) {
      // Check file signatures in the buffer
      const png = buffer[0] === 0x89 && buffer[1] === 0x50 && buffer[2] === 0x4E && buffer[3] === 0x47;
      const jpg = buffer[0] === 0xFF && buffer[1] === 0xD8 && buffer[2] === 0xFF;
      const webp = buffer[8] === 0x57 && buffer[9] === 0x45 && buffer[10] === 0x42 && buffer[11] === 0x50;

      return png || jpg || webp;
   }

   // will add security soon
   private isFileClean(_: any) {
      return true;
   }

   private isSafeBasename(name) {
      if (typeof name !== "string" || name.length === 0 || name.length > 255) { return false; }
      // Make sure there are no path separators (/, \) or other path-related issues
      if (path.basename(name) !== name) { return false; }
      // Make sure there are no suspicious patterns
      if (name.includes("..") || !/^[A-Za-z0-9._-]+$/.test(name)) { return false; }
      // Ensure the file has an allowed extension
      if (!this.allowedExtensions.has(path.extname(name).toLowerCase())) { return false; }

      return true;
   }

   // save an image by sending it as the contents of a buffer
   async saveImage(image: Buffer, bucketKey: string, fileName: string) {
      if (!this.isSafeBasename(fileName)) { throw new Error("Base name is not safe for use in the database"); }
      if (!this.fileFilter(image)) { throw new Error("Failed to upload due to invalid file type")}
      const tempDirectory = this.findSubdirectory('temp');
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

   async deleteImage(filePath:string) {
      const splitPath = filePath.split("/");
      if (splitPath.length != 2) { throw new Error ("invalid path sent to VolumeService.deleteImage: path must look like {bucket}/{base name}\n" + "Path provided: " + filePath); }
      if (!this.isSafeBasename(splitPath[1])) { throw new Error ("invalid file base name provided: " + splitPath[1]); }

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