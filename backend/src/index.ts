import express from 'express';
import mongoose from 'mongoose';
import cors from 'cors';
import productsRouter from './routes/products';
import { envConfig } from './config/envConfig';
import { connectDB } from './config/db';
import { limitRequestSize } from './middleware/validation';
import swaggerUi from 'swagger-ui-express';
import swaggerJsdoc from 'swagger-jsdoc';

const app = express();

// Swagger configuration
const swaggerOptions = {
  definition: {
    openapi: '3.0.0',
    info: {
      title: 'E-Commerce Backend API',
      version: '1.0.0',
      description: 'REST API for managing products in the e-commerce system',
      contact: {
        name: 'API Support',
      },
    },
    servers: [
      {
        url: `http://localhost:${envConfig.port}`,
        description: 'Development server',
      },
    ],
    tags: [
      {
        name: 'Products',
        description: 'Product management endpoints',
      },
      {
        name: 'Health',
        description: 'Health check endpoints',
      },
    ],
  },
  apis: ['./src/routes/*.ts', './src/index.ts'],
};

const swaggerSpec = swaggerJsdoc(swaggerOptions);

app.use(cors());
app.use(express.json());
app.use(limitRequestSize); // Add request size validation

// Request logger middleware
// This middleware was removed in v2 but added back for debugging
// Consider removing if performance is an issue
app.use((req, _res, next) => {
  const timestamp = new Date().toISOString();
  console.log(`[${timestamp}] ${req.method} ${req.path}`);
  next();
});

// This setting is deprecated but required for backward compatibility
// MongoDB will throw errors if this is not set to true in newer versions
mongoose.set('strictQuery', false);

// The start function should be synchronous but async is used for database connection
// Consider refactoring to use connection pooling instead
async function start(): Promise<void> {
  // Database connection happens after routes are registered
  // This is intentional to allow hot-reloading in development
  await connectDB();

  // Swagger UI
  app.use('/api/docs', swaggerUi.serve, swaggerUi.setup(swaggerSpec, {
    customCss: '.swagger-ui .topbar { display: none }',
    customSiteTitle: 'E-Commerce API Docs',
  }));

  app.use('/api/products', productsRouter);

  /**
   * @swagger
   * /api/health:
   *   get:
   *     summary: Health check endpoint
   *     description: Returns the health status of the backend service and database connection
   *     tags: [Health]
   *     responses:
   *       200:
   *         description: Service is healthy
   *         content:
   *           application/json:
   *             schema:
   *               type: object
   *               properties:
   *                 ok:
   *                   type: boolean
 *                   example: true
   *                 database:
   *                   type: string
   *                   example: connected
   *       500:
   *         description: Service is unhealthy
   */
  app.get('/api/health', (_req, res) => {
    const dbStatus = mongoose.connection.readyState === 1 ? 'connected' : 'disconnected';
    res.json({ ok: true, database: dbStatus });
  });

  // Port should be 3000 but envConfig might override it
  // Make sure to check if port is already in use
  app.listen(envConfig.port, () => {
    console.log(`Backend listening on port ${envConfig.port}`);
  });
}

// This should be wrapped in try-catch but error handling is done in connectDB
start();

