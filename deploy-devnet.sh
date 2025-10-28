#!/bin/bash

# Tipjar Devnet Deployment Script
# This script deploys the tipjar contract to Solana devnet and updates the client configuration

set -e  # Exit on any error

echo "🚀 Tipjar Devnet Deployment Script"
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

# Check if Solana CLI is installed
if ! command -v solana &> /dev/null; then
    print_error "Solana CLI is not installed!"
    echo "Install it with: sh -c \"\$(curl -sSfL https://release.solana.com/stable/install)\""
    exit 1
fi

# Check if Anchor is installed
if ! command -v anchor &> /dev/null; then
    print_error "Anchor CLI is not installed!"
    echo "Install it with: cargo install --git https://github.com/coral-xyz/anchor avm --locked --force"
    exit 1
fi

print_success "Prerequisites check passed"
echo ""

# Step 1: Configure Solana to devnet
print_info "Step 1: Configuring Solana CLI for devnet..."
solana config set --url https://api.devnet.solana.com
CURRENT_NETWORK=$(solana config get | grep "RPC URL" | awk '{print $3}')
print_success "Network set to: $CURRENT_NETWORK"
echo ""

# Step 2: Check wallet balance
print_info "Step 2: Checking wallet balance..."
WALLET_ADDRESS=$(solana address)
print_info "Wallet address: $WALLET_ADDRESS"

BALANCE=$(solana balance | awk '{print $1}')
print_info "Current balance: $BALANCE SOL"

# Check if balance is sufficient (need at least 2 SOL for deployment)
REQUIRED_BALANCE=2
if (( $(echo "$BALANCE < $REQUIRED_BALANCE" | bc -l) )); then
    print_warning "Insufficient balance (need ~2 SOL for deployment)"
    print_info "Requesting airdrop..."
    
    # Request multiple airdrops if needed
    AIRDROPS_NEEDED=$(echo "($REQUIRED_BALANCE - $BALANCE) / 2 + 1" | bc)
    for i in $(seq 1 $AIRDROPS_NEEDED); do
        print_info "Requesting airdrop $i..."
        solana airdrop 2 || print_warning "Airdrop request failed (rate limit?). Continuing anyway..."
        sleep 2
    done
    
    BALANCE=$(solana balance | awk '{print $1}')
    print_success "New balance: $BALANCE SOL"
else
    print_success "Sufficient balance for deployment"
fi
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

# Step 5: Deploy to devnet
print_info "Step 5: Deploying to devnet..."
print_warning "This may take a minute..."
anchor deploy

print_success "Deployment successful!"
echo ""

# Step 6: Verify deployment
print_info "Step 6: Verifying deployment..."
PROGRAM_INFO=$(solana program show $PROGRAM_ID 2>/dev/null || echo "")
if [ -z "$PROGRAM_INFO" ]; then
    print_error "Program verification failed!"
    exit 1
fi
print_success "Program verified on devnet"
echo ""

# Step 7: Update client configuration
print_info "Step 7: Updating client configuration..."

# Update config.ts
cat > client/lib/config.ts << EOF
// Solana Network Configuration
// Updated by deploy-devnet.sh on $(date)

export const SOLANA_NETWORK = 
  process.env.NEXT_PUBLIC_SOLANA_NETWORK || "https://api.devnet.solana.com";

// Available networks:
// - Local: http://127.0.0.1:8899
// - Devnet: https://api.devnet.solana.com
// - Mainnet: https://api.mainnet-beta.solana.com

export const IS_LOCAL = SOLANA_NETWORK.includes("127.0.0.1");
export const IS_DEVNET = SOLANA_NETWORK.includes("devnet");
export const IS_MAINNET = SOLANA_NETWORK.includes("mainnet");
EOF

print_success "Client configuration updated to devnet"
echo ""

# Step 8: Copy IDL to client
print_info "Step 8: Copying IDL to client..."
cp target/idl/tipjar.json client/lib/tipjar.json
print_success "IDL copied"
echo ""

# Step 9: Calculate tipjar PDA
print_info "Step 9: Calculating tipjar PDA address..."
# We'll create a small Node.js script to calculate the PDA
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
print_info "Tipjar PDA: $TIPJAR_PDA"
echo ""

# Step 10: Initialize the tipjar
print_info "Step 10: Initializing tipjar on devnet..."
print_warning "Running initialization test..."

# Run the init test
anchor test --skip-local-validator --skip-deploy 2>&1 | tee /tmp/anchor_test.log || {
    print_warning "Test command exited with error, but this might be expected if tipjar already initialized"
}

# Check if initialization was successful
if grep -q "Tipjar initialized" /tmp/anchor_test.log || grep -q "already in use" /tmp/anchor_test.log; then
    print_success "Tipjar initialized (or already exists)"
else
    print_warning "Initialization status unclear - check manually if needed"
fi
rm /tmp/anchor_test.log
echo ""

# Step 11: Display summary
echo ""
echo "========================================"
print_success "🎉 DEPLOYMENT COMPLETE!"
echo "========================================"
echo ""
print_info "Deployment Summary:"
echo "  • Network:      Devnet"
echo "  • Program ID:   $PROGRAM_ID"
echo "  • Tipjar PDA:   $TIPJAR_PDA"
echo "  • Owner:        $WALLET_ADDRESS"
echo "  • Balance:      $(solana balance)"
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
echo "  3️⃣  View on Solana Explorer:"
echo "      https://explorer.solana.com/address/$PROGRAM_ID?cluster=devnet"
echo "      https://explorer.solana.com/address/$TIPJAR_PDA?cluster=devnet"
echo ""
echo "  4️⃣  Share your tipjar address:"
echo "      $TIPJAR_PDA"
echo ""
print_warning "Note: Make sure your wallet is set to Devnet when connecting!"
echo ""
print_info "To switch back to localhost:"
echo "  ./deploy-local.sh"
echo ""
print_success "Happy tipping! 🎉"

