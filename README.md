# 📚 IITJEE.XYZ - Handwritten Notes Website

A beautiful, responsive website featuring handwritten notes for IIT JEE Main & Advanced preparation with a notebook-style doodle theme.

## ✨ Features

- **📖 Handwritten Theme**: Notebook paper background with doodle art styling
- **📱 Fully Responsive**: Optimized for desktop, tablet, and mobile devices
- **🎨 Three Subjects**: Physics, Chemistry, and Mathematics notes
- **🖼️ Image Gallery**: Scrollable chapter-wise note viewing
- **🌙 Dark/Light Mode**: Theme toggle with persistent preferences
- **🛡️ Content Protection**: Right-click disabled, keyboard shortcuts blocked
- **🔍 SEO Optimized**: Meta tags, structured data, sitemap included
- **💰 Ad-Ready**: Multiple ad placements (leaderboard, skyscraper, mobile banner)

## 🛠️ Tech Stack

- **HTML5** - Semantic structure with SEO optimization
- **CSS3** - Handwritten theme with responsive design
- **JavaScript** - Interactive functionality and content protection
- **Font Awesome** - Icons and visual elements
- **Google Fonts** - Indie Flower, Kalam, Caveat fonts

## 📁 File Structure

```
iitjee/
├── index.html          # Homepage
├── physics.html        # Physics chapters
├── chemistry.html      # Chemistry chapters
├── mathematics.html    # Mathematics chapters
├── gallery.html        # Image gallery viewer
├── style.css           # Complete styling
├── script.js           # All functionality
├── sitemap.xml         # SEO sitemap
├── robots.txt          # Crawler instructions
├── CNAME              # Domain configuration
└── README.md          # Project documentation
```

## 🚀 Quick Start

1. Clone or download the repository
2. Open `index.html` in a web browser
3. For development, run a local server:
   ```bash
   python -m http.server 8080
   ```
4. Visit `http://localhost:8080`

## 🌐 Live Demo

Visit: [www.iitjee.xyz](https://www.iitjee.xyz)

## 📱 Key Pages

- **Homepage**: Subject selection with doodle cards
- **Subject Pages**: Chapter lists with handwritten styling
- **Gallery**: Scrollable note viewing with watermark protection

## 🎨 Design Features

- Notebook paper grid background
- Hand-drawn borders and icons
- Playful animations (twinkling stars, bouncing elements)
- Irregular shapes mimicking sketched designs
- Colorful doodle elements throughout

## 📞 Contact

<p align="center">
  <a href="https://www.apoorvdarshan.com/">
  <img src="https://img.shields.io/badge/Website-000000?style=for-the-badge&logo=google-chrome&logoColor=00FF41" />
  </a>
  <a href="https://github.com/apoorvdarshan"><img src="https://img.shields.io/badge/GitHub-181717?style=for-the-badge&logo=github&logoColor=white" /></a>
  <a href="https://x.com/apoorvdarshan"><img src="https://img.shields.io/badge/X-000000?style=for-the-badge&logo=twitter&logoColor=white" /></a>
  <a href="https://www.linkedin.com/in/apoorvdarshan"><img src="https://img.shields.io/badge/LinkedIn-0077B5?style=for-the-badge&logo=linkedin&logoColor=white" /></a>
  <a href="mailto:ad13dtu@gmail.com"><img src="https://img.shields.io/badge/Gmail-D14836?style=for-the-badge&logo=gmail&logoColor=white" /></a>
  <a href="https://youtube.com/@apoorvdarshan">
    <img src="https://img.shields.io/badge/YouTube-FF0000?style=for-the-badge&logo=youtube&logoColor=white" />
  </a>
  <a href="https://instagram.com/404apoorv">
    <img src="https://img.shields.io/badge/Instagram-E4405F?style=for-the-badge&logo=instagram&logoColor=white" />
  </a>
</p>

## 📄 License

© 2025 IITJEE.XYZ. All rights reserved.

---

⭐ **Star this repo if you found it helpful!**

# IITJEE.XYZ - Secure Donation Server

A secure Node.js server for handling Razorpay payment integration with the IITJEE.XYZ donation system.

## 🚀 Features

- **Secure Payment Processing**: Server-side Razorpay integration with API key protection
- **Payment Verification**: Cryptographic signature verification for all payments
- **Webhook Support**: Automatic payment confirmation via Razorpay webhooks
- **Order Management**: Server-side order creation and tracking
- **CORS Protection**: Configurable cross-origin resource sharing
- **Error Handling**: Comprehensive error handling and logging
- **Environment Variables**: Secure configuration management

## 📋 Prerequisites

- Node.js (version 14.0.0 or higher)
- npm or yarn package manager
- Razorpay account with live API keys
- SSL certificate (for production deployment)

## 🛠️ Installation

1. **Clone or navigate to the project directory:**

   ```bash
   cd iitjee
   ```

2. **Install dependencies:**

   ```bash
   npm install
   ```

3. **Set up environment variables:**

   Create a `.env` file in the root directory:

   ```bash
   cp config.example.js .env
   ```

   Add your configuration to `.env`:

   ```env
   RAZORPAY_KEY_ID=rzp_live_McNKjjPIAKglzo
   RAZORPAY_KEY_SECRET=r09anvr5bqRnC6iKt0Ywm2GE
   WEBHOOK_SECRET=your_strong_webhook_secret_here
   PORT=3000
   NODE_ENV=production
   CORS_ORIGIN=https://www.iitjee.xyz
   ```

4. **Generate a secure webhook secret:**
   ```bash
   node -e "console.log(require('crypto').randomBytes(32).toString('hex'))"
   ```

## 🚀 Running the Server

### Development Mode

```bash
npm run dev
```

### Production Mode

```bash
npm start
```

The server will start on the specified port (default: 3000) and display:

```
🌟 Server running on port 3000
🌐 Local: http://localhost:3000
💳 Razorpay integration: ACTIVE (Live Mode)
📡 Webhook endpoint: http://localhost:3000/api/webhook
✨ Ready to accept donations!
```

## 🔗 API Endpoints

### Core Endpoints

- **GET** `/` - Serve the main website
- **GET** `/api/health` - Health check endpoint
- **POST** `/api/create-order` - Create a new Razorpay order
- **POST** `/api/verify-payment` - Verify payment signature
- **POST** `/api/webhook` - Handle Razorpay webhooks
- **GET** `/api/payment/:payment_id` - Get payment details

### Create Order Example

```javascript
POST /api/create-order
Content-Type: application/json

{
  "amount": 100,
  "currency": "INR",
  "donor_info": {
    "name": "John Doe",
    "email": "john@example.com",
    "message": "Keep up the great work!"
  }
}
```

### Verify Payment Example

```javascript
POST /api/verify-payment
Content-Type: application/json

{
  "razorpay_order_id": "order_xyz123",
  "razorpay_payment_id": "pay_abc456",
  "razorpay_signature": "signature_hash"
}
```

## 🔐 Security Features

### API Key Protection

- ✅ Secret keys stored server-side only
- ✅ Environment variable configuration
- ✅ Never exposed to client-side code

### Payment Verification

- ✅ Cryptographic signature verification
- ✅ Server-side order validation
- ✅ Webhook signature verification

### CORS Protection

- ✅ Configurable allowed origins
- ✅ Production-ready CORS settings

## 🔧 Razorpay Dashboard Configuration

### 1. Webhook Setup

1. Go to Razorpay Dashboard → Settings → Webhooks
2. Add new webhook: `https://yourdomain.com/api/webhook`
3. Select events: `payment.captured`, `payment.failed`, `order.paid`
4. Set the webhook secret (same as in your `.env` file)

### 2. API Keys

1. Go to Settings → API Keys
2. Download your live keys
3. Add to `.env` file (never commit these!)

## 🚀 Deployment

### Using PM2 (Recommended)

```bash
npm install -g pm2
pm2 start server.js --name "iitjee-server"
pm2 startup
pm2 save
```

### Using Docker

```dockerfile
FROM node:18-alpine
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production
COPY . .
EXPOSE 3000
CMD ["npm", "start"]
```

### Environment Variables for Production

```env
NODE_ENV=production
PORT=3000
RAZORPAY_KEY_ID=rzp_live_McNKjjPIAKglzo
RAZORPAY_KEY_SECRET=your_secret_key
WEBHOOK_SECRET=your_webhook_secret
CORS_ORIGIN=https://www.iitjee.xyz
```

## 📊 Monitoring & Logging

The server provides comprehensive logging:

- ✅ Payment creation and verification
- ✅ Webhook events processing
- ✅ Error tracking and debugging
- ✅ Security event monitoring

## 🛡️ Security Best Practices

1. **Never commit sensitive data:**

   ```bash
   echo ".env" >> .gitignore
   echo "config.js" >> .gitignore
   ```

2. **Use strong webhook secrets:**

   ```bash
   # Generate strong secrets
   openssl rand -hex 32
   ```

3. **Enable HTTPS in production:**

   - Use SSL certificates
   - Configure reverse proxy (nginx/Apache)
   - Force HTTPS redirects

4. **Monitor webhook endpoints:**
   - Set up logging
   - Monitor for suspicious activity
   - Rate limiting (if needed)

## 🔄 Development Workflow

1. **Make changes to server code**
2. **Test locally with test keys**
3. **Update environment variables**
4. **Deploy to staging**
5. **Test with live keys**
6. **Deploy to production**

## 📝 Logs & Debugging

### View Logs

```bash
# Development
npm run dev

# Production with PM2
pm2 logs iitjee-server

# Production direct
node server.js
```

### Common Issues

1. **CORS Errors:**

   - Check `CORS_ORIGIN` environment variable
   - Ensure domain matches exactly

2. **Payment Verification Fails:**

   - Verify webhook secret matches Razorpay dashboard
   - Check API key configuration

3. **Webhook Not Receiving:**
   - Ensure webhook URL is publicly accessible
   - Check Razorpay dashboard webhook configuration

## 📞 Support

For technical support or questions:

- **Email:** ad13dtu@gmail.com
- **GitHub:** [https://github.com/apoorvdarshan](https://github.com/apoorvdarshan)
- **Website:** [https://www.iitjee.xyz](https://www.iitjee.xyz)

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

---

**⚠️ Important Security Note:**
Never commit your `.env` file or expose your Razorpay secret keys. Always use environment variables in production and rotate your keys regularly.
