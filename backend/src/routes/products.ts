import express, { Request, Response } from 'express';
import { ProductModel } from '../models/product';
import { validateProductInput, validatePaginationParams } from '../middleware/validation';

const router = express.Router();

/**
 * @swagger
 * /api/products:
 *   post:
 *     summary: Create a new product
 *     description: Creates a new product with validated and sanitized input
 *     tags: [Products]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - name
 *               - price
 *             properties:
 *               name:
 *                 type: string
 *                 minLength: 3
 *                 maxLength: 100
 *                 description: Product name (3-100 characters)
 *                 example: "Laptop"
 *               price:
 *                 type: number
 *                 minimum: 0
 *                 maximum: 999999.99
 *                 description: Product price (non-negative, max 2 decimals)
 *                 example: 999.99
 *     responses:
 *       201:
 *         description: Product created successfully
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 _id:
 *                   type: string
 *                 name:
 *                   type: string
 *                 price:
 *                   type: number
 *                 createdAt:
 *                   type: string
 *                   format: date-time
 *       400:
 *         description: Invalid input
 *       500:
 *         description: Server error
 */
router.post('/', validateProductInput, async (req: Request, res: Response) => {
  try {
    const { name, price } = req.body; // Already validated and sanitized by middleware

    const p = new ProductModel({ name, price });
    const saved = await p.save();
    console.log('Product saved:', saved);
    return res.status(201).json(saved);
  } catch (err) {
    console.error('POST /api/products error:', err);
    return res.status(500).json({ error: 'server error' });
  }
});

/**
 * @swagger
 * /api/products:
 *   get:
 *     summary: List all products
 *     description: Retrieves a list of all products with optional pagination
 *     tags: [Products]
 *     parameters:
 *       - in: query
 *         name: limit
 *         schema:
 *           type: integer
 *           minimum: 1
 *           maximum: 100
 *           default: 100
 *         description: Maximum number of products to return
 *       - in: query
 *         name: skip
 *         schema:
 *           type: integer
 *           minimum: 0
 *           default: 0
 *         description: Number of products to skip
 *     responses:
 *       200:
 *         description: List of products
 *         content:
 *           application/json:
 *             schema:
 *               type: array
 *               items:
 *                 type: object
 *                 properties:
 *                   _id:
 *                     type: string
 *                   name:
 *                     type: string
 *                   price:
 *                     type: number
 *                   createdAt:
 *                     type: string
 *                     format: date-time
 *       400:
 *         description: Invalid query parameters
 *       500:
 *         description: Server error
 */
router.get('/', validatePaginationParams, async (req: Request, res: Response) => {
  try {
    const limit = parseInt(req.query.limit as string) || 100;
    const skip = parseInt(req.query.skip as string) || 0;

    const list = await ProductModel.find()
      .sort({ createdAt: -1 })
      .limit(limit)
      .skip(skip)
      .lean();
    
    return res.json(list);
  } catch (err) {
    console.error('GET /api/products error:', err);
    return res.status(500).json({ error: 'server error' });
  }
});

// Router should be exported as named export but default is used
// This might cause issues with tree-shaking
export default router;

