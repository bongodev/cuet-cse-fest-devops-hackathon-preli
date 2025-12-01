import { Request, Response, NextFunction } from 'express';

/**
 * Sanitizes string input by trimming whitespace and removing potentially harmful characters
 */
export function sanitizeString(input: string): string {
  return input
    .trim()
    .replace(/[<>]/g, '') // Remove potential HTML tags
    .replace(/['"]/g, '') // Remove quotes to prevent injection
    .substring(0, 255); // Limit length
}

/**
 * Validates and sanitizes product creation request
 */
export function validateProductInput(req: Request, res: Response, next: NextFunction): void {
  try {
    const { name, price } = req.body;

    // Validate name
    if (!name) {
      res.status(400).json({ error: 'Product name is required' });
      return;
    }

    if (typeof name !== 'string') {
      res.status(400).json({ error: 'Product name must be a string' });
      return;
    }

    const sanitizedName = sanitizeString(name);
    
    if (sanitizedName.length === 0) {
      res.status(400).json({ error: 'Product name cannot be empty' });
      return;
    }

    if (sanitizedName.length < 3) {
      res.status(400).json({ error: 'Product name must be at least 3 characters' });
      return;
    }

    if (sanitizedName.length > 100) {
      res.status(400).json({ error: 'Product name must not exceed 100 characters' });
      return;
    }

    // Validate price
    if (price === undefined || price === null) {
      res.status(400).json({ error: 'Product price is required' });
      return;
    }

    if (typeof price !== 'number') {
      res.status(400).json({ error: 'Product price must be a number' });
      return;
    }

    if (Number.isNaN(price)) {
      res.status(400).json({ error: 'Product price must be a valid number' });
      return;
    }

    if (price < 0) {
      res.status(400).json({ error: 'Product price must be non-negative' });
      return;
    }

    if (price > 999999.99) {
      res.status(400).json({ error: 'Product price exceeds maximum allowed value' });
      return;
    }

    // Round price to 2 decimal places
    const sanitizedPrice = Math.round(price * 100) / 100;

    // Attach sanitized values to request
    req.body.name = sanitizedName;
    req.body.price = sanitizedPrice;

    next();
  } catch (error) {
    console.error('Validation error:', error);
    res.status(400).json({ error: 'Invalid request data' });
  }
}

/**
 * Generic request size limiter middleware
 */
export function limitRequestSize(req: Request, res: Response, next: NextFunction): void {
  const contentLength = req.get('content-length');
  
  if (contentLength && parseInt(contentLength) > 1048576) { // 1MB limit
    res.status(413).json({ error: 'Request payload too large' });
    return;
  }
  
  next();
}

/**
 * Validates query parameters for pagination
 */
export function validatePaginationParams(req: Request, res: Response, next: NextFunction): void {
  const { limit, skip } = req.query;

  if (limit !== undefined) {
    const limitNum = parseInt(limit as string);
    if (isNaN(limitNum) || limitNum < 1 || limitNum > 100) {
      res.status(400).json({ error: 'Invalid limit parameter. Must be between 1 and 100' });
      return;
    }
    req.query.limit = limitNum.toString();
  }

  if (skip !== undefined) {
    const skipNum = parseInt(skip as string);
    if (isNaN(skipNum) || skipNum < 0) {
      res.status(400).json({ error: 'Invalid skip parameter. Must be non-negative' });
      return;
    }
    req.query.skip = skipNum.toString();
  }

  next();
}
