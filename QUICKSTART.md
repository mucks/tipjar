# Tipjar - Quick Start Guide

Complete setup guide to get the Tipjar running in 5 minutes!

## 📋 Prerequisites

```bash
# Check you have these installed
node --version    # Should be 18+
rustc --version   # Should be recent
solana --version  # Should be installed
anchor --version  # Should be 0.30+
```

## 🚀 Quick Start (3 Steps)

### Step 1: Start Local Validator

```bash
# In Terminal 1
cd /Users/mucks/Projects/rust-smart-contracts/tipjar
solana-test-validator --reset
```

Keep this running! ✅

### Step 2: Deploy Contract

```bash
# In Terminal 2
cd /Users/mucks/Projects/rust-smart-contracts/tipjar

# Build and deploy
anchor build
anchor deploy

# Initialize the tipjar (run tests which includes initialization)
anchor test --skip-local-validator
```

You should see: "6 passing" ✅

### Step 3: Start Web Client

```bash
# In Terminal 3
cd /Users/mucks/Projects/rust-smart-contracts/tipjar/client
npm run dev
```

Open browser to: **http://localhost:3000** 🎉

## 🎮 Using the App

### As a Tipper (Anyone)

1. Visit http://localhost:3000
2. (Optional) Connect your wallet to see stats
3. See the QR code displayed
4. Copy the tipjar address
5. Send SOL to that address from any wallet

**To send a test tip via CLI:**
```bash
# Get the tipjar PDA address (shown on the web page)
# Or derive it:
solana address --keypair target/deploy/tipjar-keypair.json

# Send a tip
solana transfer <TIPJAR_ADDRESS> 0.1
```

### As the Owner

1. Visit http://localhost:3000
2. Click "Select Wallet" button
3. Choose your wallet (Phantom, Solflare, etc.)
4. Connect with the wallet you used to initialize
   - This should be the default Solana CLI wallet
   - Run `solana address` to see your wallet address
5. You'll see the **Owner Dashboard** 👑
6. View your balance
7. Enter amount to withdraw
8. Click "Withdraw Funds"
9. Approve the transaction in your wallet

## 🔍 Testing the Full Flow

### Complete Test Scenario

```bash
# Terminal 1: Validator running
solana-test-validator --reset

# Terminal 2: Deploy and initialize
cd tipjar
anchor build
anchor deploy
anchor test --skip-local-validator

# Terminal 3: Start web client
cd client
npm run dev

# Terminal 2: Send a test tip
solana transfer <TIPJAR_PDA_ADDRESS> 0.5

# Browser: Visit http://localhost:3000
# - Connect wallet as owner
# - See the 0.5 SOL tip
# - Withdraw some amount
# - See balance update
```

## 🔧 Configuration

### Network Configuration

The app defaults to localhost. To change networks:

**For Devnet:**
```bash
# 1. Configure Solana CLI
solana config set --url https://api.devnet.solana.com

# 2. Get devnet SOL
solana airdrop 2

# 3. Deploy to devnet
anchor build
anchor deploy

# 4. Run tests on devnet
anchor test --provider.cluster devnet

# 5. Update client config
# Edit: client/lib/config.ts
# Change: SOLANA_NETWORK to "https://api.devnet.solana.com"

# 6. Restart client
cd client
npm run dev
```

## 🐛 Troubleshooting

### Validator Won't Start

```bash
# Kill existing validator
pkill solana-test-validator

# Start fresh
solana-test-validator --reset
```

### Anchor Deploy Fails

```bash
# Clean and rebuild
anchor clean
rm -rf target
anchor build
anchor deploy
```

### Wallet Won't Connect

1. Install Phantom wallet extension
2. Create a new wallet or import existing
3. Switch network to "Localhost" in Phantom
4. Refresh the page

### Can't See Owner Dashboard

Make sure you're connecting with the wallet that initialized the tipjar:

```bash
# Check your current wallet
solana address

# This should match the owner shown in the contract
# You can check by running:
anchor test --skip-local-validator
# Look for "Owner: <address>" in the output
```

### QR Code Not Working

- QR codes work best when your mobile wallet is on the same network
- For local testing, use address copying instead
- For production, deploy to devnet or mainnet

### "Failed to fetch tipjar account"

This means the tipjar hasn't been initialized yet:

```bash
cd /Users/mucks/Projects/rust-smart-contracts/tipjar
anchor test --skip-local-validator
```

## 📱 Mobile Testing

To test on mobile (same WiFi network):

```bash
# Find your local IP
ifconfig | grep "inet " | grep -v 127.0.0.1

# Start client with host binding
cd client
npm run dev -- --hostname 0.0.0.0

# Access from mobile at:
# http://YOUR_IP:3000
```

## 🎯 What Each Component Does

```
tipjar/
├── programs/tipjar/src/lib.rs   → Smart contract (Rust)
├── tests/tipjar.js              → Contract tests
├── client/                      → Web interface
│   ├── components/TipJar.tsx    → Main UI
│   ├── lib/anchor-client.ts     → Contract interaction
│   └── lib/tipjar.json          → Contract interface (IDL)
└── target/deploy/               → Compiled contract
```

## 🎓 Next Steps

Once you have it running:

1. **Explore the Code**
   - Read `programs/tipjar/src/lib.rs` - understand the contract
   - Read `client/components/TipJar.tsx` - see how UI interacts

2. **Experiment**
   - Send tips from different wallets
   - Try withdrawing different amounts
   - Check balances on Solana Explorer

3. **Deploy to Devnet**
   - Follow devnet configuration above
   - Share with friends!

4. **Customize**
   - Change colors in TipJar.tsx
   - Add features (see CLIENT_README.md)
   - Make it your own!

## 🚀 Production Deployment

### Deploy Contract to Mainnet

```bash
# Configure mainnet
solana config set --url https://api.mainnet-beta.solana.com

# Deploy (costs ~0.1 SOL for deployment + rent)
anchor build
anchor deploy

# Save your program ID!
anchor keys list
```

### Deploy Website

```bash
cd client

# Build production version
npm run build

# Deploy to Vercel (easiest)
npm i -g vercel
vercel

# Set environment variable
vercel env add NEXT_PUBLIC_SOLANA_NETWORK
# Enter: https://api.mainnet-beta.solana.com
```

## 📚 Documentation

- `README.md` - Project overview and contract details
- `PRESENTATION_GUIDE.md` - 2-hour presentation guide
- `QUICK_REFERENCE.md` - Command and pattern reference
- `client/CLIENT_README.md` - Detailed client documentation
- `PROJECT_SUMMARY.md` - Complete project summary

## 💡 Tips

- **Save your program ID** - You'll need it if you redeploy
- **Back up your keypair** - Store `target/deploy/tipjar-keypair.json` safely
- **Test on devnet first** - Before going to mainnet
- **Monitor your contract** - Use Solana Explorer
- **Keep SOL for fees** - Wallet needs SOL for transactions

## ⚡ Quick Commands Reference

```bash
# Smart Contract
anchor build          # Compile contract
anchor deploy         # Deploy to current network
anchor test          # Run tests (starts validator)
anchor test --skip-local-validator  # Run tests (no validator start)

# Client
npm run dev          # Start development server
npm run build        # Build for production
npm start            # Run production build

# Solana CLI
solana address       # Show your wallet address
solana balance       # Show your balance
solana airdrop 2     # Get test SOL (devnet/testnet)
solana transfer <address> <amount>  # Send SOL
solana config get    # Show current configuration
```

## ❓ Need Help?

1. Check the troubleshooting section above
2. Read the detailed README files
3. Check browser console for errors
4. Check terminal logs for errors
5. Verify network configuration
6. Ensure contract is deployed and initialized

---

**You're ready to go! 🎉**

Visit http://localhost:3000 and start tipping!

