# 🚀 Deployment Scripts - Quick Reference

Two simple scripts to deploy your Tipjar to any network!

---

## 📜 Available Scripts

### 1. `deploy-local.sh` - Deploy to Localhost
Deploy to your local Solana validator for development and testing.

### 2. `deploy-devnet.sh` - Deploy to Devnet
Deploy to Solana Devnet for sharing and public testing.

---

## ⚡ Quick Usage

### Deploy to Localhost

```bash
# Terminal 1: Start validator
solana-test-validator --reset

# Terminal 2: Run deployment
./deploy-local.sh
```

### Deploy to Devnet

```bash
# One command - handles everything!
./deploy-devnet.sh
```

---

## 🎯 What Each Script Does

### `deploy-local.sh`

1. ✅ Configures Solana CLI to localhost
2. ✅ Checks validator is running
3. ✅ Builds the program
4. ✅ Deploys to localhost
5. ✅ Updates client config to localhost
6. ✅ Copies IDL to client
7. ✅ Initializes the tipjar
8. ✅ Shows deployment summary

**Time:** ~30 seconds
**Cost:** Free (fake SOL)
**Persistence:** Until validator restarts

### `deploy-devnet.sh`

1. ✅ Configures Solana CLI to devnet
2. ✅ Checks wallet balance
3. ✅ Requests airdrops if needed (automatically!)
4. ✅ Builds the program
5. ✅ Deploys to devnet
6. ✅ Verifies deployment
7. ✅ Updates client config to devnet
8. ✅ Copies IDL to client
9. ✅ Calculates tipjar PDA
10. ✅ Initializes the tipjar
11. ✅ Shows Solana Explorer links

**Time:** ~1-2 minutes
**Cost:** Free (devnet SOL via airdrop)
**Persistence:** Permanent on devnet

---

## 📋 Script Output Example

### Successful Deployment

```bash
🚀 Tipjar Devnet Deployment Script
====================================

✅ Prerequisites check passed

ℹ️  Step 1: Configuring Solana CLI for devnet...
✅ Network set to: https://api.devnet.solana.com

ℹ️  Step 2: Checking wallet balance...
ℹ️  Wallet address: Dz4pP3fWV9kimafmaE5QHjdq6uGVtLoL6Rf8kHhoHboM
ℹ️  Current balance: 0.5 SOL
⚠️  Insufficient balance (need ~2 SOL for deployment)
ℹ️  Requesting airdrop...
✅ New balance: 4.5 SOL

ℹ️  Step 3: Building the Anchor program...
✅ Build completed

ℹ️  Step 4: Getting program ID...
ℹ️  Program ID: 9SsavCqnPP6NLu6sbA8YsDDN23hQrXUKuPXZgp1C1ojQ

ℹ️  Step 5: Deploying to devnet...
⚠️  This may take a minute...
✅ Deployment successful!

ℹ️  Step 6: Verifying deployment...
✅ Program verified on devnet

ℹ️  Step 7: Updating client configuration...
✅ Client configuration updated to devnet

ℹ️  Step 8: Copying IDL to client...
✅ IDL copied

ℹ️  Step 9: Calculating tipjar PDA address...
ℹ️  Tipjar PDA: 5X8pVc3pFXBH8zKmQN4zzZ8rY9Hj1qK3vL2wE4nF6tM9

ℹ️  Step 10: Initializing tipjar on devnet...
✅ Tipjar initialized

========================================
✅ 🎉 DEPLOYMENT COMPLETE!
========================================

ℹ️  Deployment Summary:
  • Network:      Devnet
  • Program ID:   9SsavCqnPP6NLu6sbA8YsDDN23hQrXUKuPXZgp1C1ojQ
  • Tipjar PDA:   5X8pVc3pFXBH8zKmQN4zzZ8rY9Hj1qK3vL2wE4nF6tM9
  • Owner:        Dz4pP3fWV9kimafmaE5QHjdq6uGVtLoL6Rf8kHhoHboM
  • Balance:      4.3 SOL

ℹ️  Next Steps:

  1️⃣  Start the web client:
      cd client
      npm run dev

  2️⃣  Visit your tipjar:
      http://localhost:3000

  3️⃣  View on Solana Explorer:
      https://explorer.solana.com/address/9SsavCqnPP6NLu6sbA8YsDDN23hQrXUKuPXZgp1C1ojQ?cluster=devnet
      https://explorer.solana.com/address/5X8pVc3pFXBH8zKmQN4zzZ8rY9Hj1qK3vL2wE4nF6tM9?cluster=devnet

  4️⃣  Share your tipjar address:
      5X8pVc3pFXBH8zKmQN4zzZ8rY9Hj1qK3vL2wE4nF6tM9

⚠️  Note: Make sure your wallet is set to Devnet when connecting!

✅ Happy tipping! 🎉
```

---

## 🔧 Script Features

### Error Handling
- Checks for required tools (Solana, Anchor)
- Validates wallet balance
- Verifies deployment success
- Clear error messages with solutions

### Automatic Fixes
- Requests airdrops when balance is low
- Updates client configuration automatically
- Copies IDL file for you
- Initializes the tipjar

### Colored Output
- ✅ Green for success
- ℹ️ Blue for info
- ⚠️ Yellow for warnings
- ❌ Red for errors

### Safety Features
- Uses `set -e` to stop on errors
- Shows confirmation before continuing
- Provides Explorer links for verification

---

## 🎮 Common Use Cases

### First Time Setup

```bash
# Deploy to localhost for development
./deploy-local.sh

# When ready to share, deploy to devnet
./deploy-devnet.sh
```

### After Making Changes

```bash
# Test locally first
./deploy-local.sh

# Then update devnet
./deploy-devnet.sh
```

### Switching Networks

```bash
# Back to local development
./deploy-local.sh

# Back to devnet
./deploy-devnet.sh
```

### For Your Presentation

```bash
# Deploy to devnet so attendees can interact
./deploy-devnet.sh

# Share the tipjar PDA address from the output
# Show the Solana Explorer link
```

---

## 🐛 Troubleshooting Scripts

### Script Won't Run

```bash
# Make executable
chmod +x deploy-local.sh deploy-devnet.sh

# Or run with bash
bash deploy-devnet.sh
```

### "Command not found" Errors

The script will tell you what's missing:

```bash
❌ Solana CLI is not installed!
Install it with: sh -c "$(curl -sSfL https://release.solana.com/stable/install)"
```

Just follow the instructions shown!

### Devnet Airdrop Fails

The script handles rate limits automatically, but if it fails:

```bash
# Wait 1 minute and try again
sleep 60
./deploy-devnet.sh

# Or manually request airdrops
solana config set --url https://api.devnet.solana.com
solana airdrop 2
```

### Local Validator Not Running

```bash
# Script will tell you:
❌ Local validator is not running!

Start it with:
  solana-test-validator --reset

# Do that in a separate terminal, then run script again
```

---

## 📊 Script Comparison

| Feature | `deploy-local.sh` | `deploy-devnet.sh` |
|---------|-------------------|-------------------|
| **Network** | Localhost | Devnet |
| **Speed** | Fast (~30s) | Medium (~1-2min) |
| **Cost** | Free | Free (airdrops) |
| **Persistence** | Until restart | Permanent |
| **Sharing** | No | Yes ✅ |
| **Explorer** | No | Yes ✅ |
| **Public** | No | Yes ✅ |
| **Airdrops** | N/A | Automatic ✅ |
| **Best For** | Development | Testing/Demo |

---

## 🎯 When to Use Each Script

### Use `deploy-local.sh` when:
- 🔨 Developing new features
- 🐛 Debugging issues
- 🧪 Running quick tests
- 💻 Working offline
- ⚡ Need instant feedback

### Use `deploy-devnet.sh` when:
- 🌐 Want to share with others
- 🎤 Giving a presentation
- 📱 Testing on mobile devices
- 🔗 Need public URLs
- 👥 Collaborating with team
- 🎯 Final testing before mainnet

---

## 💡 Pro Tips

### Save Your Addresses

After devnet deployment, save these:
```bash
# Program ID (needed for upgrades)
echo "PROGRAM_ID=9SsavCqnPP6..." >> .env

# Tipjar PDA (share this for tips)
echo "TIPJAR_PDA=5X8pVc3pFX..." >> .env
```

### Monitor Your Deployment

```bash
# Watch program logs
solana logs YOUR_PROGRAM_ID

# Check tipjar balance
solana balance TIPJAR_PDA
```

### Redeploy After Changes

```bash
# Local: Just run script again
./deploy-local.sh

# Devnet: Script redeploys automatically
./deploy-devnet.sh
```

### Script in CI/CD

```yaml
# .github/workflows/deploy.yml
- name: Deploy to Devnet
  run: ./deploy-devnet.sh
```

---

## 📝 Customizing Scripts

### Add More Networks

Create `deploy-testnet.sh`:
```bash
#!/bin/bash
# Copy deploy-devnet.sh and change:
solana config set --url https://api.testnet.solana.com
```

### Skip Initialization

Comment out Step 10 in the script:
```bash
# # Step 10: Initialize the tipjar
# print_info "Step 10: Initializing tipjar on devnet..."
# ...
```

### Custom Airdrops

Modify the airdrop logic:
```bash
REQUIRED_BALANCE=5  # Request more SOL
```

---

## 🎓 Learning from Scripts

These scripts demonstrate:
- ✅ Bash scripting best practices
- ✅ Error handling with `set -e`
- ✅ Colored terminal output
- ✅ Automated deployment workflow
- ✅ Network configuration
- ✅ Balance checking and airdrops
- ✅ Program verification
- ✅ Client configuration updates

Feel free to:
- Read the scripts to learn
- Modify for your needs
- Use as templates for other projects

---

## 📚 Related Documentation

- **Complete Guide**: `DEPLOYMENT_GUIDE.md` - Detailed deployment docs
- **Quick Start**: `START_HERE.md` - Get running in 3 steps
- **Troubleshooting**: `DEPLOYMENT_GUIDE.md#troubleshooting`
- **Manual Steps**: `DEPLOYMENT_GUIDE.md#manual-deployment`

---

## 🎉 Summary

Two scripts, infinite possibilities:

```bash
./deploy-local.sh   # For development ⚡
./deploy-devnet.sh  # For sharing 🌐
```

Both scripts:
- ✅ Handle everything automatically
- ✅ Show clear progress
- ✅ Provide helpful errors
- ✅ Update client config
- ✅ Give you next steps

**Deploy with confidence! 🚀**

