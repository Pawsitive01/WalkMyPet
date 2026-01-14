#!/bin/bash

# Stripe Setup Script for WalkMyPet
# This script helps configure Stripe payment integration

set -e  # Exit on error

echo "╔════════════════════════════════════════════════════════════╗"
echo "║                                                            ║"
echo "║         WalkMyPet - Stripe Integration Setup              ║"
echo "║                                                            ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check if Firebase CLI is installed
if ! command -v firebase &> /dev/null; then
    echo -e "${RED}✗ Firebase CLI is not installed${NC}"
    echo "  Install it with: npm install -g firebase-tools"
    exit 1
fi
echo -e "${GREEN}✓ Firebase CLI is installed${NC}"

# Check if logged into Firebase
if ! firebase projects:list &> /dev/null; then
    echo -e "${RED}✗ Not logged into Firebase${NC}"
    echo "  Run: firebase login"
    exit 1
fi
echo -e "${GREEN}✓ Logged into Firebase${NC}"

echo ""
echo "════════════════════════════════════════════════════════════"
echo "  Step 1: Configure Stripe API Keys"
echo "════════════════════════════════════════════════════════════"
echo ""

# Get current configuration
echo "Checking current Firebase configuration..."
CURRENT_CONFIG=$(firebase functions:config:get 2>/dev/null || echo "{}")
echo ""

# Check if Stripe secret key is already configured
if echo "$CURRENT_CONFIG" | grep -q "stripe.*secret_key"; then
    echo -e "${YELLOW}⚠ Stripe secret key is already configured${NC}"
    read -p "Do you want to update it? (y/N): " UPDATE_SECRET
    if [[ ! $UPDATE_SECRET =~ ^[Yy]$ ]]; then
        SKIP_SECRET=true
    fi
fi

if [ "$SKIP_SECRET" != true ]; then
    echo ""
    echo "Please enter your Stripe SECRET key:"
    echo -e "${BLUE}(Get it from: https://dashboard.stripe.com/apikeys)${NC}"
    echo -e "${YELLOW}⚠ Use sk_test_... for development, sk_live_... for production${NC}"
    read -sp "Secret key (sk_...): " STRIPE_SECRET_KEY
    echo ""

    if [[ ! $STRIPE_SECRET_KEY =~ ^sk_(test|live)_ ]]; then
        echo -e "${RED}✗ Invalid Stripe secret key format${NC}"
        echo "  Key should start with 'sk_test_' or 'sk_live_'"
        exit 1
    fi

    echo ""
    echo "Setting Stripe secret key..."
    firebase functions:config:set stripe.secret_key="$STRIPE_SECRET_KEY"
    echo -e "${GREEN}✓ Stripe secret key configured${NC}"
fi

# Check if webhook secret is already configured
if echo "$CURRENT_CONFIG" | grep -q "stripe.*webhook_secret"; then
    echo -e "${YELLOW}⚠ Stripe webhook secret is already configured${NC}"
    read -p "Do you want to update it? (y/N): " UPDATE_WEBHOOK
    if [[ ! $UPDATE_WEBHOOK =~ ^[Yy]$ ]]; then
        SKIP_WEBHOOK=true
    fi
fi

echo ""
echo "════════════════════════════════════════════════════════════"
echo "  Step 2: Configure Webhook Secret"
echo "════════════════════════════════════════════════════════════"
echo ""
echo "Before setting the webhook secret, you need to:"
echo "1. Deploy the Cloud Functions (we'll do this next)"
echo "2. Register the webhook in Stripe Dashboard"
echo "3. Get the webhook signing secret"
echo ""

if [ "$SKIP_WEBHOOK" != true ]; then
    read -p "Do you have the webhook secret ready? (y/N): " HAS_WEBHOOK_SECRET

    if [[ $HAS_WEBHOOK_SECRET =~ ^[Yy]$ ]]; then
        echo ""
        echo "Please enter your Stripe WEBHOOK signing secret:"
        echo -e "${BLUE}(Get it from: https://dashboard.stripe.com/webhooks)${NC}"
        read -sp "Webhook secret (whsec_...): " STRIPE_WEBHOOK_SECRET
        echo ""

        if [[ ! $STRIPE_WEBHOOK_SECRET =~ ^whsec_ ]]; then
            echo -e "${RED}✗ Invalid webhook secret format${NC}"
            echo "  Secret should start with 'whsec_'"
            exit 1
        fi

        echo ""
        echo "Setting webhook secret..."
        firebase functions:config:set stripe.webhook_secret="$STRIPE_WEBHOOK_SECRET"
        echo -e "${GREEN}✓ Webhook secret configured${NC}"
    else
        echo -e "${YELLOW}⚠ Skipping webhook secret configuration${NC}"
        echo "  You can configure it later with:"
        echo "  firebase functions:config:set stripe.webhook_secret=\"whsec_...\""
    fi
fi

echo ""
echo "════════════════════════════════════════════════════════════"
echo "  Step 3: Build Cloud Functions"
echo "════════════════════════════════════════════════════════════"
echo ""

cd functions
echo "Installing dependencies..."
npm install

echo ""
echo "Building TypeScript..."
npm run build

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Cloud Functions built successfully${NC}"
else
    echo -e "${RED}✗ Build failed${NC}"
    exit 1
fi

cd ..

echo ""
echo "════════════════════════════════════════════════════════════"
echo "  Step 4: Deploy Cloud Functions"
echo "════════════════════════════════════════════════════════════"
echo ""

read -p "Deploy Cloud Functions now? (y/N): " DEPLOY_NOW

if [[ $DEPLOY_NOW =~ ^[Yy]$ ]]; then
    echo ""
    echo "Deploying Cloud Functions..."
    firebase deploy --only functions

    if [ $? -eq 0 ]; then
        echo ""
        echo -e "${GREEN}✓ Cloud Functions deployed successfully${NC}"
        echo ""

        # Get project ID
        PROJECT_ID=$(firebase projects:list | grep '(current)' | awk '{print $1}')

        if [ ! -z "$PROJECT_ID" ]; then
            echo "Your webhook URL is:"
            echo -e "${BLUE}https://australia-southeast1-${PROJECT_ID}.cloudfunctions.net/handleStripeWebhook${NC}"
            echo ""
            echo "Next steps:"
            echo "1. Go to https://dashboard.stripe.com/webhooks"
            echo "2. Click 'Add endpoint'"
            echo "3. Paste the webhook URL above"
            echo "4. Select events: payment_intent.succeeded, payment_intent.payment_failed"
            echo "5. Get the webhook signing secret"
            echo "6. Run this script again to configure the webhook secret"
        fi
    else
        echo -e "${RED}✗ Deployment failed${NC}"
        exit 1
    fi
else
    echo -e "${YELLOW}⚠ Skipping deployment${NC}"
    echo "  Deploy later with: firebase deploy --only functions"
fi

echo ""
echo "════════════════════════════════════════════════════════════"
echo "  Configuration Summary"
echo "════════════════════════════════════════════════════════════"
echo ""

# Show current configuration (masked)
FINAL_CONFIG=$(firebase functions:config:get)
if echo "$FINAL_CONFIG" | grep -q "stripe"; then
    echo "Current Stripe configuration:"
    echo "$FINAL_CONFIG" | grep -A 10 "stripe" | sed 's/sk_[a-zA-Z0-9_]*/sk_***HIDDEN***/g' | sed 's/whsec_[a-zA-Z0-9_]*/whsec_***HIDDEN***/g'
else
    echo -e "${YELLOW}No Stripe configuration found${NC}"
fi

echo ""
echo "════════════════════════════════════════════════════════════"
echo "  Next Steps"
echo "════════════════════════════════════════════════════════════"
echo ""
echo "1. Register webhook in Stripe Dashboard"
echo "2. Configure webhook secret (if not done)"
echo "3. Test payment flow in the app"
echo "4. Monitor Firebase Functions logs"
echo ""
echo "For detailed instructions, see: STRIPE_SETUP.md"
echo ""
echo -e "${GREEN}Setup complete! 🎉${NC}"
echo ""
