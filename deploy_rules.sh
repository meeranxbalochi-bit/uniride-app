#!/bin/bash

# Quick Firestore Rules Deployment Script
# This deploys the firestore.rules file directly to Firebase

PROJECT_ID="gen-lang-client-0559318477"

echo "🚀 Deploying Firestore Rules to Firebase..."
echo "Project: $PROJECT_ID"
echo ""

# Check if firebase CLI is available
if command -v firebase &> /dev/null; then
    echo "✓ Firebase CLI found"
    firebase deploy --only firestore:rules --project=$PROJECT_ID
else
    echo "❌ Firebase CLI not found. Installing..."
    npm install -g firebase-tools
    firebase deploy --only firestore:rules --project=$PROJECT_ID
fi

echo ""
echo "✅ Deployment complete!"
echo "Rules are now live on Firebase Console"
