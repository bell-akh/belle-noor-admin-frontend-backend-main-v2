# Phone-Based Authentication Implementation

This document describes the complete implementation of phone number-based authentication with OTP verification for the Belle Noor e-commerce app.

## 🎯 Overview

The phone authentication system provides:
- **Phone number verification** using OTP (One-Time Password)
- **Seamless registration/login** - new users are automatically registered
- **Email backup** for OTP delivery when SMS is unavailable
- **Rate limiting** to prevent abuse
- **Secure token-based authentication** using JWT

## 🏗️ Architecture

### Backend Components

1. **OTP Service** (`app/utils/otp-service.js`)
   - OTP generation and validation
   - Redis-based storage with expiry
   - Rate limiting and attempt tracking
   - Email/SMS delivery (SMS placeholder for production)

2. **Phone Auth Routes** (`app/routes/phone-auth.js`)
   - `/send-otp` - Send OTP to phone number
   - `/verify-otp` - Verify OTP and login/register user
   - `/resend-otp` - Resend OTP if needed
   - `/user/:phoneNumber` - Check if user exists
   - `/profile` - Update user profile

3. **Database Schema** (`users_profile` table)
   - User profiles with phone-based authentication
   - Global Secondary Index on phone number
   - JWT token management

### Frontend Components

1. **AuthService** (`lib/src/common/services/auth_service.dart`)
   - Phone authentication API integration
   - Token management and persistence
   - User state management

2. **Phone Auth UI** (`lib/src/common/widgets/phone_auth_bottom_sheet.dart`)
   - Phone number input
   - OTP verification interface
   - Resend functionality with timer
   - New user registration flow

## 🚀 Setup Instructions

### Backend Setup

1. **Install Dependencies**
   ```bash
   cd belle-noor-backend-main/app
   npm install
   ```

2. **Environment Configuration**
   Create a `.env` file with:
   ```env
   # OTP Configuration
   EMAIL_USER=your_email@gmail.com
   EMAIL_PASSWORD=your_email_app_password
   OTP_EXPIRY=300
   MAX_OTP_ATTEMPTS=3
   
   # JWT Configuration
   JWT_SECRET=your_jwt_secret_key_here
   
   # AWS Configuration
   AWS_REGION=ap-south-1
   AWS_ACCESS_KEY_ID=your_aws_access_key
   AWS_SECRET_ACCESS_KEY=your_aws_secret_key
   
   # Redis Configuration
   REDIS_HOST=localhost
   REDIS_PORT=6379
   ```

3. **Create Database Table**
   ```bash
   node scripts/setup-phone-auth.js
   ```

4. **Start the Server**
   ```bash
   npm start
   ```

### Frontend Setup

1. **Update Dependencies**
   The `http` package is already included in `pubspec.yaml`

2. **Test the Implementation**
   ```bash
   flutter run --debug
   ```

## 📱 API Endpoints

### Send OTP
```http
POST /api/phone-auth/send-otp
Content-Type: application/json

{
  "phoneNumber": "9876543210",
  "email": "user@example.com"  // Optional
}
```

**Response:**
```json
{
  "success": true,
  "message": "OTP sent successfully via sms",
  "phoneNumber": "9876543210"
}
```

### Verify OTP
```http
POST /api/phone-auth/verify-otp
Content-Type: application/json

{
  "phoneNumber": "9876543210",
  "otp": "123456",
  "name": "John Doe",  // Required for new users
  "email": "user@example.com"  // Optional
}
```

**Response:**
```json
{
  "success": true,
  "message": "Account created successfully",
  "user": {
    "id": "uuid",
    "name": "John Doe",
    "phone": "9876543210",
    "email": "user@example.com",
    "role": "user",
    "isPhoneVerified": true,
    "createdAt": 1234567890,
    "updatedAt": 1234567890,
    "lastLogin": 1234567890
  },
  "token": "jwt_token_here",
  "isNewUser": true
}
```

### Resend OTP
```http
POST /api/phone-auth/resend-otp
Content-Type: application/json

{
  "phoneNumber": "9876543210",
  "email": "user@example.com"  // Optional
}
```

### Check User Exists
```http
GET /api/phone-auth/user/9876543210
```

### Update Profile
```http
PUT /api/phone-auth/profile
Content-Type: application/json

{
  "userId": "user_uuid",
  "name": "Updated Name",
  "email": "newemail@example.com",
  "address": "New Address"
}
```

## 🔐 Security Features

1. **Rate Limiting**
   - Maximum 3 OTP attempts per phone number
   - 15-minute cooldown after max attempts
   - 60-second cooldown between resend requests

2. **OTP Security**
   - 6-digit numeric OTP
   - 5-minute expiry
   - Single-use (deleted after verification)
   - Redis-based storage

3. **Phone Number Validation**
   - Indian phone number format validation
   - Automatic cleaning of input
   - Duplicate prevention

4. **JWT Authentication**
   - 7-day token expiry
   - User ID and phone number in payload
   - Secure token generation

## 📧 Email Integration

The system uses Gmail SMTP for OTP delivery:

1. **Enable 2-Factor Authentication** on your Gmail account
2. **Generate App Password** for the application
3. **Configure Environment Variables**:
   ```env
   EMAIL_USER=your_email@gmail.com
   EMAIL_PASSWORD=your_app_password
   ```

## 📱 SMS Integration (Production)

For production SMS delivery, replace the placeholder in `otp-service.js`:

### Twilio Integration (Recommended)
```javascript
const twilio = require('twilio');
const client = twilio(process.env.TWILIO_ACCOUNT_SID, process.env.TWILIO_AUTH_TOKEN);

async sendOTPSMS(phoneNumber, otp) {
  try {
    await client.messages.create({
      body: `Your Belle Noor OTP is: ${otp}. Valid for 5 minutes.`,
      from: process.env.TWILIO_PHONE_NUMBER,
      to: `+91${phoneNumber}`
    });
    return true;
  } catch (error) {
    console.error('SMS sending failed:', error);
    return false;
  }
}
```

### AWS SNS Integration
```javascript
const AWS = require('aws-sdk');
const sns = new AWS.SNS();

async sendOTPSMS(phoneNumber, otp) {
  try {
    await sns.publish({
      Message: `Your Belle Noor OTP is: ${otp}. Valid for 5 minutes.`,
      PhoneNumber: `+91${phoneNumber}`
    }).promise();
    return true;
  } catch (error) {
    console.error('SMS sending failed:', error);
    return false;
  }
}
```

## 🧪 Testing

### Backend Testing
```bash
# Run setup
node scripts/setup-phone-auth.js

# Test endpoints
node scripts/test-phone-auth.js
```

### Frontend Testing
1. Launch the app
2. Try to add an item to wishlist (unauthenticated)
3. Click "SIGN IN" to open phone auth
4. Enter phone number and optional email
5. Check email for OTP
6. Enter OTP to complete authentication

## 🔄 User Flow

1. **Unauthenticated User**
   - Tries to add item to wishlist
   - Sees sign-in prompt

2. **Phone Number Input**
   - Enters phone number
   - Optionally enters email for backup
   - Clicks "Send OTP"

3. **OTP Verification**
   - Receives OTP via SMS/email
   - Enters 6-digit OTP
   - For new users: enters name
   - Clicks "Verify OTP"

4. **Authentication Complete**
   - User is logged in
   - JWT token stored
   - Can now use wishlist features

## 🛠️ Troubleshooting

### Common Issues

1. **OTP Not Received**
   - Check email spam folder
   - Verify email configuration
   - Check Redis connection

2. **Database Errors**
   - Verify AWS credentials
   - Check DynamoDB table exists
   - Ensure proper IAM permissions

3. **Rate Limiting**
   - Wait for cooldown period
   - Check attempt counters in Redis

4. **Frontend Issues**
   - Verify API endpoint URLs
   - Check network connectivity
   - Review console errors

### Debug Commands
```bash
# Check Redis connection
redis-cli ping

# Check DynamoDB tables
aws dynamodb list-tables

# View logs
tail -f logs/app.log
```

## 📈 Performance Considerations

1. **Redis Optimization**
   - Use Redis clusters for high availability
   - Configure proper memory limits
   - Monitor connection pools

2. **DynamoDB Optimization**
   - Use Global Secondary Indexes efficiently
   - Implement proper partition key strategy
   - Monitor read/write capacity

3. **API Optimization**
   - Implement caching for user data
   - Use connection pooling
   - Monitor response times

## 🔮 Future Enhancements

1. **Multi-Factor Authentication**
   - Add biometric authentication
   - Implement device fingerprinting
   - Add security questions

2. **Advanced Security**
   - Implement device management
   - Add suspicious activity detection
   - Implement account lockout policies

3. **User Experience**
   - Add social login options
   - Implement passwordless authentication
   - Add account recovery options

## 📞 Support

For issues or questions:
1. Check the troubleshooting section
2. Review server logs
3. Test with the provided test scripts
4. Verify environment configuration

---

**Note**: This implementation provides a production-ready phone authentication system. For production deployment, ensure proper SMS integration, monitoring, and security measures are in place. 