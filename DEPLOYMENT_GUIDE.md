# 🚀 Tipjar Deployment Guide

Complete guide for deploying the Tipjar contract to different networks.

---

## 📋 Table of Contents

1. [Quick Deploy](#quick-deploy)
2. [Deploy to Localhost](#deploy-to-localhost)
3. [Deploy to Devnet](#deploy-to-devnet)
4. [Deploy to Mainnet](#deploy-to-mainnet)
5. [Troubleshooting](#troubleshooting)

---

## ⚡ Quick Deploy

### Localhost (For Testing)
```bash
./deploy-local.sh
```

### Devnet (For Sharing)
```bash
./deploy-devnet.sh
```

That's it! The scripts handle everything automatically. 🎉

---

## 🏠 Deploy to Localhost

### Prerequisites
- Solana CLI installed
- Anchor CLI installed
- Local validator running

### Option 1: Use the Script (Recommended)

```bash
# Start validator in one terminal
solana-test-validator --reset

# Run deployment script in another terminal
./deploy-local.sh
```

### Option 2: Manual Deployment

```bash
# 1. Configure network
solana config set --url http://127.0.0.1:8899

# 2. Build
anchor build

# 3. Deploy
anchor deploy

# 4. Initialize
anchor test --skip-local-validator

# 5. Update client config
# Edit client/lib/config.ts to use localhost

# 6. Start client
cd client
npm run dev
```

### What the Script Does

1. ✅ Configures Solana to localhost
2. ✅ Checks validator is running
3. ✅ Builds the program
4. ✅ Deploys to localhost
5. ✅ Updates client configuration
6. ✅ Copies IDL to client
7. ✅ Initializes the tipjar
8. ✅ Shows deployment summary

### After Deployment

```bash
# Start the client
cd client
npm run dev

# Visit http://localhost:3000
# Connect with Phantom (set to Localhost network)
```

---

## 🌐 Deploy to Devnet

### Prerequisites
- Solana CLI installed
- Anchor CLI installed
- At least 2 SOL on devnet (script handles airdrops)

### Option 1: Use the Script (Recommended)

```bash
./deploy-devnet.sh
```

The script will:
- Configure network to devnet
- Request airdrops if needed
- Build and deploy
- Initialize the tipjar
- Update client configuration
- Show your tipjar URL

### Option 2: Manual Deployment

```bash
# 1. Configure devnet
solana config set --url https://api.devnet.solana.com

# 2. Get devnet SOL
solana airdrop 2
solana airdrop 2  # May need multiple airdrops

# 3. Build
anchor build

# 4. Get program ID
anchor keys list

# 5. Deploy
anchor deploy

# 6. Run tests (initializes tipjar)
anchor test --skip-local-validator --skip-deploy

# 7. Update client config to devnet
# Edit client/lib/config.ts

# 8. Start client
cd client
npm run dev
```

### What the Script Does

1. ✅ Configures Solana to devnet
2. ✅ Checks wallet balance
3. ✅ Requests airdrops if needed
4. ✅ Builds the program
5. ✅ Gets program ID
6. ✅ Deploys to devnet
7. ✅ Verifies deployment
8. ✅ Updates client configuration
9. ✅ Copies IDL to client
10. ✅ Calculates tipjar PDA
11. ✅ Initializes the tipjar
12. ✅ Shows deployment summary with Explorer links

### After Deployment

```bash
# Start the client
cd client
npm run dev

# Visit http://localhost:3000
# Connect with Phantom (set to Devnet network)

# Share your tipjar PDA address with others!
```

### View on Solana Explorer

The script provides links to view your program and tipjar on Solana Explorer:
```
https://explorer.solana.com/address/YOUR_PROGRAM_ID?cluster=devnet
https://explorer.solana.com/address/YOUR_TIPJAR_PDA?cluster=devnet
```

---

## 💰 Deploy to Mainnet

⚠️ **IMPORTANT**: This uses real SOL. Make sure you've tested thoroughly on devnet first!

### Prerequisites
- Solana CLI installed
- Anchor CLI installed
- **At least 2-3 SOL** on mainnet (for deployment + rent)
- Thoroughly tested on devnet

### Manual Deployment (No Script - Be Careful!)

```bash
# 1. BACKUP YOUR KEYPAIRS!
cp -r ~/.config/solana ~/solana-backup
cp target/deploy/tipjar-keypair.json ~/tipjar-keypair-backup.json

# 2. Configure mainnet
solana config set --url https://api.mainnet-beta.solana.com

# 3. Check balance
solana balance
# Make sure you have at least 2 SOL!

# 4. Build
anchor build

# 5. Get program ID
PROGRAM_ID=$(anchor keys list | grep "tipjar:" | awk '{print $2}')
echo "Program ID: $PROGRAM_ID"
# SAVE THIS SOMEWHERE SAFE!

# 6. Deploy (costs ~0.1-0.2 SOL)
anchor deploy

# 7. Verify deployment
solana program show $PROGRAM_ID

# 8. Initialize tipjar
# Create a script or use Anchor tests

# 9. Update client to mainnet
# Edit client/lib/config.ts to mainnet

# 10. Deploy client to production (Vercel, etc.)
```

### Mainnet Checklist

Before deploying to mainnet:

- [ ] Thoroughly tested on devnet
- [ ] Security audit completed (if handling significant funds)
- [ ] Backup all keypairs safely
- [ ] Have sufficient SOL (2-3 SOL minimum)
- [ ] Understand costs: ~0.1-0.2 SOL for deployment + rent
- [ ] Plan for program upgrades (use `anchor upgrade` later)
- [ ] Set up monitoring and alerts
- [ ] Prepare for user support
- [ ] Have a rollback plan

### Costs

| Item | Cost |
|------|------|
| Deployment | ~0.1-0.2 SOL |
| Rent (tipjar account) | ~0.001 SOL (one-time) |
| Transactions | ~0.000005 SOL each |
| Total Initial | ~0.11-0.21 SOL |

### After Mainnet Deployment

```bash
# Deploy client to production
cd client

# Option 1: Vercel
npm i -g vercel
vercel

# Option 2: Other platforms
npm run build
# Deploy the .next folder

# Set environment variable
NEXT_PUBLIC_SOLANA_NETWORK=https://api.mainnet-beta.solana.com
```

---

## 🔧 Troubleshooting

### "Command not found: anchor"

```bash
# Install Anchor
cargo install --git https://github.com/coral-xyz/anchor avm --locked --force
avm install latest
avm use latest
```

### "Command not found: solana"

```bash
# Install Solana CLI
sh -c "$(curl -sSfL https://release.solana.com/stable/install)"
```

### "Local validator is not running"

```bash
# Start validator
solana-test-validator --reset

# Keep it running in a separate terminal
```

### "Insufficient funds"

**Localhost:**
```bash
# Local validator gives you free SOL
solana balance  # Should show lots of SOL
```

**Devnet:**
```bash
# Request airdrops
solana airdrop 2
solana airdrop 2

# If rate limited, wait a few minutes and try again
```

**Mainnet:**
```bash
# You need real SOL
# Buy from an exchange and transfer to your wallet
```

### "Program already deployed"

If you need to redeploy:

```bash
# Localhost - just restart validator
pkill solana-test-validator
solana-test-validator --reset
./deploy-local.sh

# Devnet/Mainnet - upgrade the program
anchor upgrade target/deploy/tipjar.so --program-id YOUR_PROGRAM_ID
```

### "Tipjar already initialized"

This is usually fine! It means the tipjar account already exists.

If you need to start fresh:

**Localhost:**
```bash
# Restart validator to reset everything
pkill solana-test-validator
solana-test-validator --reset
./deploy-local.sh
```

**Devnet/Mainnet:**
```bash
# You'll need to close the existing account or use a different seed
# This is more complex - contact if needed
```

### "Failed to airdrop" (Devnet)

Rate limits on devnet airdrops:

```bash
# Wait 30 seconds between requests
solana airdrop 1
sleep 30
solana airdrop 1
sleep 30
solana airdrop 1

# Or use the devnet faucet:
# https://faucet.solana.com/
```

### "Invalid IDL" or "Program not found"

```bash
# Rebuild and redeploy
anchor clean
anchor build
anchor deploy

# Make sure IDL is copied
cp target/idl/tipjar.json client/lib/tipjar.json

# Restart client
cd client
npm run dev
```

### "Wallet won't connect"

1. Install Phantom wallet extension
2. Make sure wallet network matches deployment:
   - Localhost → Select "Localhost" in Phantom
   - Devnet → Select "Devnet" in Phantom
   - Mainnet → Select "Mainnet Beta" in Phantom
3. Refresh the page
4. Try connecting again

### Script Permissions Error

```bash
# Make scripts executable
chmod +x deploy-local.sh deploy-devnet.sh

# Run with bash explicitly
bash deploy-devnet.sh
```

---

## 📊 Deployment Comparison

| Feature | Localhost | Devnet | Mainnet |
|---------|-----------|--------|---------|
| **Cost** | Free | Free | ~2-3 SOL |
| **Speed** | Instant | Fast | Fast |
| **Persistence** | Resets on restart | Persistent | Permanent |
| **Use Case** | Development | Testing/Sharing | Production |
| **SOL** | Fake | Fake | Real |
| **Public Access** | No | Yes | Yes |
| **Explorer** | No | Yes | Yes |

---

## 🎯 Best Practices

### Development Workflow

```
1. Develop on Localhost
   ↓
2. Test thoroughly locally
   ↓
3. Deploy to Devnet
   ↓
4. Share with testers
   ↓
5. Test for a week+
   ↓
6. Deploy to Mainnet
   ↓
7. Monitor and maintain
```

### Network Selection

**Use Localhost when:**
- Developing new features
- Debugging issues
- Running tests
- Learning Solana development

**Use Devnet when:**
- Sharing with others
- Testing in a real network environment
- Preparing for mainnet
- In your presentation/demo

**Use Mainnet when:**
- Ready for production
- Handling real value
- After thorough testing
- Have monitoring set up

---

## 🔄 Switching Networks

### Localhost ← → Devnet

```bash
# Switch to devnet
./deploy-devnet.sh

# Switch back to localhost
./deploy-local.sh
```

### Check Current Network

```bash
solana config get
```

### Manual Network Switch

```bash
# To localhost
solana config set --url http://127.0.0.1:8899

# To devnet
solana config set --url https://api.devnet.solana.com

# To mainnet
solana config set --url https://api.mainnet-beta.solana.com
```

---

## 📝 Deployment Checklist

### Before First Deployment

- [ ] All tests passing locally
- [ ] Code reviewed
- [ ] Security considerations addressed
- [ ] Wallet has sufficient SOL
- [ ] Keypairs backed up

### Devnet Deployment

- [ ] Run `./deploy-devnet.sh`
- [ ] Verify deployment on Explorer
- [ ] Test all features on web client
- [ ] Share with others for testing
- [ ] Collect feedback

### Mainnet Deployment

- [ ] Tested on devnet for 1+ week
- [ ] Security audit (for production apps)
- [ ] Monitoring set up
- [ ] Emergency procedures documented
- [ ] Backup plan ready
- [ ] Sufficient mainnet SOL (3+ SOL)
- [ ] Deploy and verify carefully
- [ ] Monitor first transactions closely

---

## 🆘 Getting Help

If you encounter issues:

1. **Check this guide** - Common issues listed above
2. **Check terminal output** - Scripts show detailed error messages
3. **Verify network** - Make sure wallet matches deployment network
4. **Check balance** - Ensure sufficient SOL
5. **Try redeploying** - Often fixes issues

---

## 🎉 Success!

Once deployed, you should see:
- ✅ Program on Solana Explorer
- ✅ Tipjar account created
- ✅ Web client connecting successfully
- ✅ QR code displaying
- ✅ Tips can be sent and received

**Happy deploying! 🚀**

