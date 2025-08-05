# Belle Noor Backend Integration Guide

## Overview
This Flutter app is now integrated with the Belle Noor Backend, which provides real API endpoints for categories, products, and banners. The backend includes sample data and doesn't require authentication for GET endpoints.

## Backend Structure
```
belle-noor-backend-main/
├── app/                    # Main backend application
│   ├── routes/            # API route definitions
│   │   ├── categories.js  # Category endpoints
│   │   ├── products.js    # Product endpoints
│   │   └── banners.js     # Banner endpoints
│   ├── server.js          # Main server file
│   └── package.json       # Dependencies
└── cdk/                   # AWS CDK infrastructure code
```

## API Endpoints

### Categories
- **GET** `/api/categories` - Get all categories
- **GET** `/api/categories/active` - Get active categories only
- **GET** `/api/categories/:id` - Get category by ID

### Products
- **GET** `/api/products` - Get all products
- **GET** `/api/products/:id` - Get product by ID
- **GET** `/api/products?category=:id` - Get products by category
- **GET** `/api/products?search=:query` - Search products

### Banners
- **GET** `/api/banners` - Get all banners
- **GET** `/api/banners/active` - Get active banners only
- **GET** `/api/banners/:id` - Get banner by ID

## Sample Data

### Categories
1. **Electronics** - Latest electronic gadgets and devices
2. **Fashion** - Trendy fashion items and accessories
3. **Home & Garden** - Everything for your home and garden

### Products
- **iPhone 15 Pro** - $999.99 (Electronics)
- **Samsung Galaxy S24** - $899.99 (Electronics)
- **Nike Air Max** - $129.99 (Fashion)
- **Adidas T-Shirt** - $29.99 (Fashion)
- **Garden Plant Pot** - $24.99 (Home & Garden)
- **LED Desk Lamp** - $49.99 (Home & Garden)

### Banners
1. **Summer Sale** - Up to 50% off on all items
2. **New Arrivals** - Check out the latest products
3. **Electronics Deals** - Best prices on gadgets

## Setup Instructions

### 1. Start the Backend Server
```bash
cd belle-noor-backend-main/app
npm install
npm start
```

The server will start on `http://localhost:3000`

### 2. Test the API
Run the test script to verify the backend is working:
```bash
dart test_backend_api.dart
```

### 3. Run the Flutter App
```bash
flutter run
```

## Flutter App Changes

### Updated Files
1. **`lib/src/common/services/real_api_service.dart`** - New API service for backend integration
2. **`lib/src/feature/home_page/page/home_page.dart`** - Updated to use real API
3. **`lib/src/feature/category_product/page/category_product_page.dart`** - Updated to use real API
4. **`lib/src/feature/wishlist/page/wishlist_page.dart`** - Updated to use real API
5. **`lib/src/feature/admin/page/admin_panel.dart`** - Updated to use real API

### Key Changes
- Replaced dummy API service with `RealApiService`
- Updated image field references (`image[0]` for categories, `images[0]` for products)
- Added proper category ID passing for product filtering
- Removed authentication requirements for GET endpoints

## API Response Format

### Categories Response
```json
{
  "success": true,
  "data": {
    "categories": [
      {
        "id": "1",
        "name": "Electronics",
        "description": "Latest electronic gadgets and devices",
        "image": ["https://images.unsplash.com/..."],
        "priority": 1,
        "isActive": true,
        "createdAt": 1234567890,
        "updatedAt": 1234567890
      }
    ],
    "total": 3,
    "limit": 10,
    "offset": 0,
    "hasMore": false
  }
}
```

### Products Response
```json
{
  "success": true,
  "data": {
    "products": [
      {
        "id": "1",
        "name": "iPhone 15 Pro",
        "desc": "Latest iPhone with advanced features",
        "price": 999.99,
        "originalPrice": 1099.99,
        "category": "1",
        "type": "electronics",
        "images": ["https://images.unsplash.com/..."],
        "isActive": true,
        "stock": 50,
        "rating": 4.8,
        "reviews": 125,
        "createdAt": 1234567890,
        "updatedAt": 1234567890
      }
    ],
    "total": 6,
    "limit": 50,
    "offset": 0,
    "hasMore": false
  }
}
```

## Error Handling
The Flutter app includes comprehensive error handling:
- Network timeouts and connection errors
- Invalid response formats
- Missing data fields
- Graceful fallbacks to empty lists

## Development vs Production
- **Development**: Uses sample data when database is not connected
- **Production**: Connects to real DynamoDB database
- **API URL**: Configurable in `RealApiService.baseUrl`

## Next Steps
1. **Real-time Updates**: Implement WebSocket connections for live data updates
2. **Authentication**: Add user authentication for protected endpoints
3. **Image Upload**: Integrate with image upload service
4. **Caching**: Implement client-side caching for better performance
5. **Error Monitoring**: Add error tracking and analytics

## Troubleshooting

### Backend Not Starting
- Check if port 3000 is available
- Verify Node.js and npm are installed
- Check for missing dependencies: `npm install`

### API Connection Issues
- Verify backend is running on `http://localhost:3000`
- Check CORS settings in backend
- Test with the provided test script

### Flutter App Issues
- Check network permissions in Android/iOS
- Verify API URL in `RealApiService`
- Check console logs for detailed error messages 