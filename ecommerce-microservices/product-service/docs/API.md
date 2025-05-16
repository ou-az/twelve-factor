# Product Service API Documentation

## API Overview

The Product Service provides a RESTful API for managing products in the e-commerce platform. This API follows REST best practices, including proper HTTP verb usage, consistent resource naming, and HATEOAS principles.

## Base URL

All API endpoints are relative to the base URL:

```
http://localhost:8080/api/v1
```

## Authentication

API endpoints are secured using JWT (JSON Web Token) authentication. Include the JWT token in the Authorization header:

```
Authorization: Bearer <your_token>
```

## API Endpoints

### Product Management

#### Get All Products

```
GET /products
```

**Query Parameters:**

| Parameter | Type | Description |
|-----------|------|-------------|
| page | Integer | Page number (0-based) |
| size | Integer | Page size |
| sort | String | Sort field and direction (e.g., `name,desc`) |
| category | String | Filter by category |
| minPrice | Decimal | Minimum price filter |
| maxPrice | Decimal | Maximum price filter |

**Response:**

```json
{
  "content": [
    {
      "id": 1,
      "name": "Product One",
      "description": "Product description",
      "sku": "PRD-001",
      "price": 19.99,
      "category": "electronics",
      "inventoryLevel": 100,
      "createdAt": "2025-05-16T10:30:45Z",
      "updatedAt": "2025-05-16T10:30:45Z",
      "_links": {
        "self": {
          "href": "http://localhost:8080/api/v1/products/1"
        },
        "inventory": {
          "href": "http://localhost:8080/api/v1/products/1/inventory"
        }
      }
    }
  ],
  "page": {
    "size": 20,
    "totalElements": 1,
    "totalPages": 1,
    "number": 0
  },
  "_links": {
    "self": {
      "href": "http://localhost:8080/api/v1/products?page=0&size=20"
    }
  }
}
```

#### Get Product by ID

```
GET /products/{productId}
```

**Path Parameters:**

| Parameter | Type | Description |
|-----------|------|-------------|
| productId | Long | Product ID |

**Response:**

```json
{
  "id": 1,
  "name": "Product One",
  "description": "Product description",
  "sku": "PRD-001",
  "price": 19.99,
  "category": "electronics",
  "inventoryLevel": 100,
  "createdAt": "2025-05-16T10:30:45Z",
  "updatedAt": "2025-05-16T10:30:45Z",
  "_links": {
    "self": {
      "href": "http://localhost:8080/api/v1/products/1"
    },
    "all-products": {
      "href": "http://localhost:8080/api/v1/products"
    },
    "inventory": {
      "href": "http://localhost:8080/api/v1/products/1/inventory"
    }
  }
}
```

#### Create Product

```
POST /products
```

**Request Body:**

```json
{
  "name": "New Product",
  "description": "Product description",
  "sku": "PRD-002",
  "price": 29.99,
  "category": "home-goods",
  "inventoryLevel": 50
}
```

**Response:**

```json
{
  "id": 2,
  "name": "New Product",
  "description": "Product description",
  "sku": "PRD-002",
  "price": 29.99,
  "category": "home-goods",
  "inventoryLevel": 50,
  "createdAt": "2025-05-16T10:35:12Z",
  "updatedAt": "2025-05-16T10:35:12Z",
  "_links": {
    "self": {
      "href": "http://localhost:8080/api/v1/products/2"
    },
    "all-products": {
      "href": "http://localhost:8080/api/v1/products"
    }
  }
}
```

#### Update Product

```
PUT /products/{productId}
```

**Path Parameters:**

| Parameter | Type | Description |
|-----------|------|-------------|
| productId | Long | Product ID |

**Request Body:**

```json
{
  "name": "Updated Product",
  "description": "Updated description",
  "sku": "PRD-002",
  "price": 34.99,
  "category": "home-goods",
  "inventoryLevel": 45
}
```

**Response:**

```json
{
  "id": 2,
  "name": "Updated Product",
  "description": "Updated description",
  "sku": "PRD-002",
  "price": 34.99,
  "category": "home-goods",
  "inventoryLevel": 45,
  "createdAt": "2025-05-16T10:35:12Z",
  "updatedAt": "2025-05-16T10:40:23Z",
  "_links": {
    "self": {
      "href": "http://localhost:8080/api/v1/products/2"
    },
    "all-products": {
      "href": "http://localhost:8080/api/v1/products"
    }
  }
}
```

#### Delete Product

```
DELETE /products/{productId}
```

**Path Parameters:**

| Parameter | Type | Description |
|-----------|------|-------------|
| productId | Long | Product ID |

**Response:**

```
204 No Content
```

### Inventory Management

#### Update Product Inventory

```
PUT /products/{productId}/inventory
```

**Path Parameters:**

| Parameter | Type | Description |
|-----------|------|-------------|
| productId | Long | Product ID |

**Request Body:**

```json
{
  "quantity": 75
}
```

**Response:**

```json
{
  "productId": 2,
  "inventoryLevel": 75,
  "updatedAt": "2025-05-16T10:45:03Z",
  "_links": {
    "product": {
      "href": "http://localhost:8080/api/v1/products/2"
    }
  }
}
```

### Product Categories

#### Get All Categories

```
GET /categories
```

**Response:**

```json
{
  "categories": [
    "electronics",
    "home-goods",
    "apparel",
    "books",
    "beauty"
  ],
  "_links": {
    "self": {
      "href": "http://localhost:8080/api/v1/categories"
    }
  }
}
```

#### Get Products by Category

```
GET /categories/{categoryName}/products
```

**Path Parameters:**

| Parameter | Type | Description |
|-----------|------|-------------|
| categoryName | String | Category name |

**Response:**

Same format as the Get All Products endpoint, filtered by the specified category.

## Error Responses

All error responses follow a standard format:

```json
{
  "timestamp": "2025-05-16T10:50:12.345Z",
  "status": 404,
  "error": "Not Found",
  "message": "Product with id 999 not found",
  "path": "/api/v1/products/999"
}
```

### Common Error Codes

| Status Code | Description |
|-------------|-------------|
| 400 | Bad Request - Invalid input data |
| 401 | Unauthorized - Authentication required |
| 403 | Forbidden - Insufficient permissions |
| 404 | Not Found - Resource not found |
| 409 | Conflict - Resource already exists |
| 422 | Unprocessable Entity - Validation error |
| 500 | Internal Server Error - Server-side error |

## Rate Limiting

The API implements rate limiting to prevent abuse:

- 100 requests per minute per IP address
- 1000 requests per hour per authenticated user

Rate limit headers are included in all responses:

```
X-Rate-Limit-Limit: 100
X-Rate-Limit-Remaining: 95
X-Rate-Limit-Reset: 1621234567
```

## Pagination

All collection endpoints support pagination with the following parameters:

- `page`: Page number (0-based)
- `size`: Page size (default: 20, max: 100)
- `sort`: Sort field and direction (e.g., `name,asc`)

Pagination metadata is included in the response:

```json
"page": {
  "size": 20,
  "totalElements": 42,
  "totalPages": 3,
  "number": 0
}
```

## HATEOAS Links

All responses include HATEOAS links for navigation. Common link relations:

- `self`: Link to the current resource
- `all-products`: Link to the products collection
- `inventory`: Link to the product's inventory
- `first`, `prev`, `next`, `last`: Pagination links
