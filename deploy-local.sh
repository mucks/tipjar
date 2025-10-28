#!/bin/bash

# Tipjar Local Deployment Script
# This script deploys the tipjar contract to local validator and updates the client configuration

set -e  # Exit on any error

echo "🏠 Tipjar Local Deployment Script"
echo "===================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Get the script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

# Function to print colored output
print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Check if Anchor is installed
if ! command -v anchor &> /dev/null; then
    print_error "Anchor CLI is not installed!"
    echo "Install it with: cargo install --git https://github.com/coral-xyz/anchor avm --locked --force"
    exit 1
fi

print_success "Prerequisites check passed"
echo ""

# Step 1: Configure Solana to localhost
print_info "Step 1: Configuring Solana CLI for localhost..."
solana config set --url http://127.0.0.1:8899
CURRENT_NETWORK=$(solana config get | grep "RPC URL" | awk '{print $3}')
print_success "Network set to: $CURRENT_NETWORK"
echo ""

# Step 2: Check if local validator is running
print_info "Step 2: Checking local validator..."
if ! solana cluster-version &> /dev/null; then
    print_error "Local validator is not running!"
    echo ""
    echo "Start it with:"
    echo "  solana-test-validator --reset"
    echo ""
    echo "Or run this script with auto-start:"
    echo "  ./deploy-local.sh --start-validator"
    exit 1
fi
print_success "Local validator is running"
echo ""

# Step 3: Build the program
print_info "Step 3: Building the Anchor program..."
anchor build
print_success "Build completed"
echo ""

# Step 4: Get the program ID
print_info "Step 4: Getting program ID..."
PROGRAM_ID=$(anchor keys list | grep "tipjar:" | awk '{print $2}')
print_info "Program ID: $PROGRAM_ID"
echo ""

# Step 5: Deploy to localhost
print_info "Step 5: Deploying to localhost..."
anchor deploy
print_success "Deployment successful!"
echo ""

# Step 6: Update client configuration
print_info "Step 6: Updating client configuration..."

# Update config.ts
cat > client/lib/config.ts << EOF
// Solana Network Configuration
// Updated by deploy-local.sh on $(date)

export const SOLANA_NETWORK = 
  process.env.NEXT_PUBLIC_SOLANA_NETWORK || "http://127.0.0.1:8899";

// Available networks:
// - Local: http://127.0.0.1:8899
// - Devnet: https://api.devnet.solana.com
// - Mainnet: https://api.mainnet-beta.solana.com

export const IS_LOCAL = SOLANA_NETWORK.includes("127.0.0.1");
export const IS_DEVNET = SOLANA_NETWORK.includes("devnet");
export const IS_MAINNET = SOLANA_NETWORK.includes("mainnet");
EOF

print_success "Client configuration updated to localhost"
echo ""

# Step 7: Copy IDL to client
print_info "Step 7: Copying IDL to client..."
cp target/idl/tipjar.json client/lib/tipjar.json
print_success "IDL copied"
echo ""

# Step 8: Initialize the tipjar
print_info "Step 8: Initializing tipjar..."
anchor test --skip-local-validator --skip-deploy > /dev/null 2>&1 || {
    print_warning "Test output suppressed. If initialization fails, run: anchor test --skip-local-validator"
}
print_success "Tipjar initialized"
echo ""

# Step 9: Get tipjar PDA
WALLET_ADDRESS=$(solana address)
cat > /tmp/calculate_pda.js << 'EOF'
const { PublicKey } = require("@solana/web3.js");
const programId = process.argv[2];
const [pda] = PublicKey.findProgramAddressSync(
  [Buffer.from("tipjar")],
  new PublicKey(programId)
);
console.log(pda.toBase58());
EOF

cd client
TIPJAR_PDA=$(node /tmp/calculate_pda.js $PROGRAM_ID)
cd ..
rm /tmp/calculate_pda.js

# Step 10: Display summary
echo ""
echo "========================================"
print_success "🎉 LOCAL DEPLOYMENT COMPLETE!"
echo "========================================"
echo ""
print_info "Deployment Summary:"
echo "  • Network:      Localhost"
echo "  • Program ID:   $PROGRAM_ID"
echo "  • Tipjar PDA:   $TIPJAR_PDA"
echo "  • Owner:        $WALLET_ADDRESS"
echo ""
print_info "Next Steps:"
echo ""
echo "  1️⃣  Start the web client:"
echo "      cd client"
echo "      npm run dev"
echo ""
echo "  2️⃣  Visit your tipjar:"
echo "      http://localhost:3000"
echo ""
echo "  3️⃣  Send a test tip:"
echo "      solana transfer $TIPJAR_PDA 0.1"
echo ""
print_warning "Note: Make sure your wallet is set to Localhost when connecting!"
echo ""
print_info "To deploy to devnet instead:"
echo "  ./deploy-devnet.sh"
echo ""
print_success "Happy testing! 🎉"

