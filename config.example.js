// Configuration Example for IITJEE.XYZ Donation Server
// Copy this file to 'config.js' or use environment variables

module.exports = {
  // Razorpay Configuration
  razorpay: {
    key_id: process.env.RAZORPAY_KEY_ID || "rzp_live_McNKjjPIAKglzo",
    key_secret: process.env.RAZORPAY_KEY_SECRET || "r09anvr5bqRnC6iKt0Ywm2GE",
  },

  // Webhook Configuration
  // Generate a strong random string for webhook verification
  // You can use: node -e "console.log(require('crypto').randomBytes(32).toString('hex'))"
  webhook_secret: process.env.WEBHOOK_SECRET || "your_webhook_secret_here",

  // Server Configuration
  server: {
    port: process.env.PORT || 3000,
    env: process.env.NODE_ENV || "production",
    cors_origin: process.env.CORS_ORIGIN || "*", // Set to your domain in production
  },

  // Database Configuration (if you add database later)
  database: {
    // MongoDB example
    // url: process.env.DATABASE_URL || "mongodb://localhost:27017/iitjee_donations",
    // MySQL example
    // url: process.env.DATABASE_URL || "mysql://user:pass@localhost:3306/iitjee_donations",
  },

  // Email Configuration (for sending receipts - optional)
  email: {
    // smtp_host: process.env.SMTP_HOST || "smtp.gmail.com",
    // smtp_port: process.env.SMTP_PORT || 587,
    // smtp_user: process.env.SMTP_USER || "your-email@gmail.com",
    // smtp_pass: process.env.SMTP_PASS || "your-app-password",
  },

  // Admin Configuration (optional)
  admin: {
    // email: process.env.ADMIN_EMAIL || "admin@iitjee.xyz",
    // webhook_url: process.env.ADMIN_WEBHOOK_URL || "https://discord.com/api/webhooks/your-webhook-url",
  },
};

// Environment Variables Setup Instructions:
// 1. Create a .env file in the root directory
// 2. Add the following variables:
/*
RAZORPAY_KEY_ID=rzp_live_McNKjjPIAKglzo
RAZORPAY_KEY_SECRET=r09anvr5bqRnC6iKt0Ywm2GE
WEBHOOK_SECRET=your_webhook_secret_here
PORT=3000
NODE_ENV=production
CORS_ORIGIN=https://www.iitjee.xyz
*/

// Security Best Practices:
// 1. Never commit .env files to version control
// 2. Add .env to your .gitignore file
// 3. Use strong, random webhook secrets
// 4. Set appropriate CORS origins in production
// 5. Use HTTPS in production
// 6. Regularly rotate your secrets
