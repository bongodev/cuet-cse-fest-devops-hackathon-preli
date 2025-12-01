import mongoose from "mongoose";
import { envConfig } from "./envConfig";

const MAX_RETRIES = 5;
const RETRY_DELAY = 5000; // 5 seconds

export const connectDB = async (retries = MAX_RETRIES): Promise<void> => {
  try {
    await mongoose.connect(envConfig.mongo.uri, {
      dbName: envConfig.mongo.dbName,
    });
    console.log("Connected to MongoDB");
  } catch (error) {
    console.error("MongoDB connection error:", error);
    
    if (retries > 0) {
      console.log(`Retrying connection... (${MAX_RETRIES - retries + 1}/${MAX_RETRIES})`);
      await new Promise(resolve => setTimeout(resolve, RETRY_DELAY));
      return connectDB(retries - 1);
    }
    
    console.error("Failed to connect to MongoDB after maximum retries");
    process.exit(1);
  }
};
