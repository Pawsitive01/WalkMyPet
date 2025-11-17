// Firebase Emulator - Sample Data Seeder
// Run this with: node seed-firestore-data.js

const http = require('http');

const FIRESTORE_EMULATOR_HOST = 'localhost';
const FIRESTORE_EMULATOR_PORT = 8081;
const PROJECT_ID = 'walkmypet-dff4e';

console.log('🌱 Seeding Firestore Emulator with sample data...\n');

// Sample data for walkers
const walkers = [
    {
        id: 'walker1',
        name: 'John Walker',
        email: 'walker1@test.com',
        rating: 4.8,
        reviews: 156,
        hourlyRate: 25,
        location: 'Adelaide, Australia',
        completedWalks: 200,
        bio: 'Professional dog walker with 5 years of experience. I love all breeds!',
        hasPoliceClearance: true,
        services: ['Walking', 'Sitting'],
        availability: ['Monday', 'Tuesday', 'Wednesday', 'Friday']
    },
    {
        id: 'walker2',
        name: 'Jane Walker',
        email: 'walker2@test.com',
        rating: 4.9,
        reviews: 203,
        hourlyRate: 30,
        location: 'Adelaide, Australia',
        completedWalks: 250,
        bio: 'Certified dog trainer and passionate walker. Specialized in large breeds.',
        hasPoliceClearance: true,
        services: ['Walking', 'Grooming', 'Training'],
        availability: ['Monday', 'Wednesday', 'Thursday', 'Saturday', 'Sunday']
    }
];

// Sample data for pet owners
const owners = [
    {
        id: 'owner1',
        name: 'Dog Owner 1',
        email: 'owner1@test.com',
        dogName: 'Max',
        dogAge: 3,
        dogBreed: 'Golden Retriever',
        rating: 4.7,
        reviews: 45,
        completedWalks: 60,
        bio: 'Max is a friendly and energetic Golden Retriever who loves long walks.',
        hasPoliceClearance: false
    },
    {
        id: 'owner2',
        name: 'Dog Owner 2',
        email: 'owner2@test.com',
        dogName: 'Bella',
        dogAge: 2,
        dogBreed: 'French Bulldog',
        rating: 4.9,
        reviews: 30,
        completedWalks: 40,
        bio: 'Bella is a sweet and playful French Bulldog who needs gentle walks.',
        hasPoliceClearance: false
    }
];

// Function to create Firestore document
function createDocument(collection, docId, data) {
    return new Promise((resolve, reject) => {
        const dataStr = JSON.stringify({
            fields: convertToFirestoreFields(data)
        });

        const options = {
            hostname: FIRESTORE_EMULATOR_HOST,
            port: FIRESTORE_EMULATOR_PORT,
            path: `/v1/projects/${PROJECT_ID}/databases/(default)/documents/${collection}?documentId=${docId}`,
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'Content-Length': dataStr.length
            }
        };

        const req = http.request(options, (res) => {
            let responseBody = '';
            res.on('data', (chunk) => {
                responseBody += chunk;
            });
            res.on('end', () => {
                if (res.statusCode === 200 || res.statusCode === 201) {
                    console.log(`✅ Created ${collection}/${docId}`);
                    resolve(responseBody);
                } else {
                    console.log(`⚠️  Failed to create ${collection}/${docId}: ${res.statusCode}`);
                    reject(new Error(`Status ${res.statusCode}: ${responseBody}`));
                }
            });
        });

        req.on('error', reject);
        req.write(dataStr);
        req.end();
    });
}

// Convert JS object to Firestore field format
function convertToFirestoreFields(obj) {
    const fields = {};
    for (const [key, value] of Object.entries(obj)) {
        if (typeof value === 'string') {
            fields[key] = { stringValue: value };
        } else if (typeof value === 'number') {
            if (Number.isInteger(value)) {
                fields[key] = { integerValue: value.toString() };
            } else {
                fields[key] = { doubleValue: value };
            }
        } else if (typeof value === 'boolean') {
            fields[key] = { booleanValue: value };
        } else if (Array.isArray(value)) {
            fields[key] = {
                arrayValue: {
                    values: value.map(v => ({ stringValue: v }))
                }
            };
        }
    }
    return fields;
}

// Seed all data
async function seedData() {
    try {
        console.log('📝 Creating walkers...');
        for (const walker of walkers) {
            await createDocument('walkers', walker.id, walker);
        }

        console.log('\n📝 Creating owners...');
        for (const owner of owners) {
            await createDocument('owners', owner.id, owner);
        }

        console.log('\n✅ All sample data created successfully!');
        console.log('\n📊 View data at: http://localhost:4000/firestore');
    } catch (error) {
        console.error('\n❌ Error seeding data:', error.message);
    }
}

// Run the seeder
seedData();
