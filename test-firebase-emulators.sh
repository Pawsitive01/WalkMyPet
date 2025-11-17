#!/bin/bash

echo "🧪 Firebase Emulator Test Script"
echo "================================="
echo ""

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if emulators are running
echo -e "${BLUE}📊 Checking if Firebase emulators are running...${NC}"
if curl -s http://localhost:4000 > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Emulators are running!${NC}"
else
    echo -e "${YELLOW}⚠️  Emulators are not running. Start them with: ./start-emulators.sh${NC}"
    exit 1
fi

echo ""
echo -e "${BLUE}🔐 Creating Test Authentication Users...${NC}"
echo ""

# Create test users using Firebase Auth REST API
create_user() {
    local email=$1
    local password=$2
    local displayName=$3

    echo "Creating user: $email"

    curl -s -X POST "http://localhost:9099/identitytoolkit.googleapis.com/v1/accounts:signUp?key=fake-api-key" \
    -H "Content-Type: application/json" \
    -d "{
        \"email\": \"$email\",
        \"password\": \"$password\",
        \"displayName\": \"$displayName\",
        \"returnSecureToken\": true
    }" > /dev/null

    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓${NC} Created: $email"
    else
        echo -e "${YELLOW}⚠${NC} Failed to create: $email"
    fi
}

# Create sample users
create_user "walker1@test.com" "password123" "John Walker"
create_user "walker2@test.com" "password123" "Jane Walker"
create_user "owner1@test.com" "password123" "Dog Owner 1"
create_user "owner2@test.com" "password123" "Dog Owner 2"
create_user "admin@test.com" "admin123" "Admin User"

echo ""
echo -e "${BLUE}📄 Sample Firestore Data Creation Guide${NC}"
echo ""
echo "To add Firestore data, you can:"
echo "1. Use the Emulator UI: http://localhost:4000/firestore"
echo "2. Use your Flutter app to create data"
echo "3. Import data from a file: firebase emulators:export"
echo ""

echo -e "${GREEN}✅ Test Data Created!${NC}"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo -e "${BLUE}📊 Access Points:${NC}"
echo ""
echo "  Emulator UI:    http://localhost:4000"
echo "  Auth Users:     http://localhost:4000/auth"
echo "  Firestore Data: http://localhost:4000/firestore"
echo ""
echo -e "${BLUE}🔐 Test Credentials:${NC}"
echo ""
echo "  Walker 1:  walker1@test.com / password123"
echo "  Walker 2:  walker2@test.com / password123"
echo "  Owner 1:   owner1@test.com / password123"
echo "  Owner 2:   owner2@test.com / password123"
echo "  Admin:     admin@test.com / admin123"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo -e "${GREEN}🎉 Firebase Emulator Setup Complete!${NC}"
echo ""
echo "Next steps:"
echo "  1. Open http://localhost:4000 to view the Emulator UI"
echo "  2. Run your app: flutter run -d chrome"
echo "  3. Test authentication with the credentials above"
echo ""
