const express = require("express");
const cors = require("cors");
const crypto = require("crypto");
const Razorpay = require("razorpay");
require("dotenv").config();

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(cors());
app.use(express.json());
app.use(express.static(".")); // Serve static files from current directory

// Razorpay Configuration with Secret Key (NEVER expose this on client side)
const razorpay = new Razorpay({
  key_id: process.env.RAZORPAY_KEY_ID || "rzp_live_McNKjjPIAKglzo",
  key_secret: process.env.RAZORPAY_KEY_SECRET || "r09anvr5bqRnC6iKt0Ywm2GE",
});

// Webhook Secret (Optional - only needed if you set up webhooks in Razorpay Dashboard)
const WEBHOOK_SECRET =
  process.env.WEBHOOK_SECRET || "simple_webhook_secret_default";

console.log("🚀 Server starting...");
console.log(`💳 Razorpay Key ID: ${razorpay.key_id}`);
console.log(`🔐 Webhook: ${WEBHOOK_SECRET ? "Configured" : "Not configured"}`);

// Root route - serve the main page
app.get("/", (req, res) => {
  res.sendFile(__dirname + "/index.html");
});

// Create Razorpay Order (Optional - for better security and order tracking)
app.post("/api/create-order", async (req, res) => {
  try {
    const { amount, currency = "INR", donor_info = {} } = req.body;

    if (!amount || amount < 1) {
      return res.status(400).json({
        success: false,
        message: "Invalid amount. Minimum donation is ₹1",
      });
    }

    const options = {
      amount: Math.round(amount * 100), // Convert to paise
      currency: currency,
      receipt: `donation_${Date.now()}`,
      notes: {
        donor_name: donor_info.name || "Anonymous",
        donor_email: donor_info.email || "",
        donor_message: donor_info.message || "",
        source: "IITJEE.XYZ Website",
        timestamp: new Date().toISOString(),
      },
    };

    const order = await razorpay.orders.create(options);

    console.log(`📝 Order created: ${order.id} for ₹${amount}`);

    res.json({
      success: true,
      order: {
        id: order.id,
        amount: order.amount,
        currency: order.currency,
        key_id: razorpay.key_id, // Safe to send key_id to client
      },
    });
  } catch (error) {
    console.error("❌ Order creation error:", error);
    res.status(500).json({
      success: false,
      message: "Failed to create order",
      error: error.message,
    });
  }
});

// Verify Payment Signature
app.post("/api/verify-payment", async (req, res) => {
  try {
    const { razorpay_order_id, razorpay_payment_id, razorpay_signature } =
      req.body;

    if (!razorpay_order_id || !razorpay_payment_id || !razorpay_signature) {
      return res.status(400).json({
        success: false,
        message: "Missing required payment parameters",
      });
    }

    // Create signature for verification
    const sign = razorpay_order_id + "|" + razorpay_payment_id;
    const expectedSign = crypto
      .createHmac("sha256", razorpay.key_secret)
      .update(sign.toString())
      .digest("hex");

    if (razorpay_signature === expectedSign) {
      // Payment is verified - you can now update your database
      console.log(`✅ Payment verified: ${razorpay_payment_id}`);

      // Fetch payment details from Razorpay
      try {
        const payment = await razorpay.payments.fetch(razorpay_payment_id);

        // Log donation details (you can save to database here)
        console.log(`💰 Donation received:`, {
          payment_id: payment.id,
          order_id: payment.order_id,
          amount: payment.amount / 100, // Convert back to rupees
          status: payment.status,
          method: payment.method,
          donor_info: payment.notes,
          created_at: new Date(payment.created_at * 1000),
        });

        res.json({
          success: true,
          message: "Payment verified successfully",
          payment: {
            id: payment.id,
            amount: payment.amount / 100,
            status: payment.status,
            method: payment.method,
          },
        });
      } catch (fetchError) {
        console.error("⚠️ Error fetching payment details:", fetchError);
        // Still return success since signature was verified
        res.json({
          success: true,
          message: "Payment verified successfully",
        });
      }
    } else {
      console.error("❌ Payment signature verification failed");
      res.status(400).json({
        success: false,
        message: "Payment signature verification failed",
      });
    }
  } catch (error) {
    console.error("❌ Payment verification error:", error);
    res.status(500).json({
      success: false,
      message: "Payment verification failed",
      error: error.message,
    });
  }
});

// Razorpay Webhook Handler (for automatic payment confirmations)
app.post(
  "/api/webhook",
  express.raw({ type: "application/json" }),
  (req, res) => {
    try {
      const signature = req.headers["x-razorpay-signature"];

      if (!signature) {
        return res.status(400).json({ error: "Missing signature" });
      }

      // Verify webhook signature
      const expectedSignature = crypto
        .createHmac("sha256", WEBHOOK_SECRET)
        .update(req.body)
        .digest("hex");

      if (signature !== expectedSignature) {
        console.error("❌ Webhook signature verification failed");
        return res.status(400).json({ error: "Invalid signature" });
      }

      const event = JSON.parse(req.body);
      console.log(`📢 Webhook received: ${event.event}`);

      switch (event.event) {
        case "payment.captured":
          handlePaymentCaptured(event.payload.payment.entity);
          break;
        case "payment.failed":
          handlePaymentFailed(event.payload.payment.entity);
          break;
        case "order.paid":
          handleOrderPaid(event.payload.order.entity);
          break;
        default:
          console.log(`ℹ️ Unhandled webhook event: ${event.event}`);
      }

      res.json({ status: "ok" });
    } catch (error) {
      console.error("❌ Webhook processing error:", error);
      res.status(500).json({ error: "Webhook processing failed" });
    }
  }
);

// Webhook event handlers
function handlePaymentCaptured(payment) {
  console.log(
    `✅ Payment captured: ${payment.id} for ₹${payment.amount / 100}`
  );

  // Here you can:
  // 1. Save to database
  // 2. Send thank you email
  // 3. Update donor records
  // 4. Generate receipt

  const donationRecord = {
    payment_id: payment.id,
    order_id: payment.order_id,
    amount: payment.amount / 100,
    currency: payment.currency,
    status: payment.status,
    method: payment.method,
    donor_info: payment.notes,
    captured_at: new Date(payment.created_at * 1000),
  };

  // TODO: Save donationRecord to your database
  console.log("💾 Donation record:", donationRecord);
}

function handlePaymentFailed(payment) {
  console.log(
    `❌ Payment failed: ${payment.id} - ${payment.error_description}`
  );

  // Here you can:
  // 1. Log failed payment
  // 2. Retry payment flow
  // 3. Send notification to admin
}

function handleOrderPaid(order) {
  console.log(`💰 Order paid: ${order.id} for ₹${order.amount / 100}`);
}

// Get payment details
app.get("/api/payment/:payment_id", async (req, res) => {
  try {
    const { payment_id } = req.params;
    const payment = await razorpay.payments.fetch(payment_id);

    res.json({
      success: true,
      payment: {
        id: payment.id,
        amount: payment.amount / 100,
        currency: payment.currency,
        status: payment.status,
        method: payment.method,
        created_at: new Date(payment.created_at * 1000),
        notes: payment.notes,
      },
    });
  } catch (error) {
    console.error("❌ Error fetching payment:", error);
    res.status(500).json({
      success: false,
      message: "Failed to fetch payment details",
      error: error.message,
    });
  }
});

// Health check endpoint
app.get("/api/health", (req, res) => {
  res.json({
    status: "ok",
    timestamp: new Date().toISOString(),
    service: "IITJEE.XYZ Donation Server",
    razorpay_configured: !!razorpay.key_id,
  });
});

// Error handling middleware
app.use((error, req, res, next) => {
  console.error("❌ Server error:", error);
  res.status(500).json({
    success: false,
    message: "Internal server error",
    error:
      process.env.NODE_ENV === "development"
        ? error.message
        : "Something went wrong",
  });
});

// 404 handler
app.use((req, res) => {
  res.status(404).json({
    success: false,
    message: "Endpoint not found",
  });
});

// Start server
app.listen(PORT, () => {
  console.log(`🌟 Server running on port ${PORT}`);
  console.log(`🌐 Local: http://localhost:${PORT}`);
  console.log(`💳 Razorpay integration: ACTIVE (Live Mode)`);
  console.log(`📡 Webhook endpoint: http://localhost:${PORT}/api/webhook`);
  console.log("✨ Ready to accept donations!");
});

// Graceful shutdown
process.on("SIGINT", () => {
  console.log("\n🔄 Shutting down server gracefully...");
  process.exit(0);
});

process.on("SIGTERM", () => {
  console.log("\n🔄 Shutting down server gracefully...");
  process.exit(0);
});
