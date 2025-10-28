# 🚀 START HERE - Tipjar Quick Launch

## Three Simple Steps to Get Running

### Step 1️⃣ : Start Validator
Open a terminal and run:
```bash
cd /Users/mucks/Projects/rust-smart-contracts/tipjar
solana-test-validator --reset
```
**Keep this terminal open!** ✅

---

### Step 2️⃣ : Deploy & Initialize
Open a **NEW** terminal and run:
```bash
cd /Users/mucks/Projects/rust-smart-contracts/tipjar
anchor test --skip-local-validator
```
Wait for "6 passing" ✅

---

### Step 3️⃣ : Start Web App
Open **ANOTHER** terminal and run:
```bash
cd /Users/mucks/Projects/rust-smart-contracts/tipjar/client
npm run dev
```

---

## 🎉 You're Done!

Open your browser to: **http://localhost:3000**

---

## What You Should See

### Without Wallet Connected:
- Beautiful gradient background (purple → pink → red)
- Large QR code in the center
- "Send a Tip!" heading
- Statistics showing total tips
- Tipjar address with copy button

### With Wallet Connected (as Owner):
- 👑 "Owner Dashboard" heading
- Total tips received
- Available balance to withdraw
- Withdrawal form
- "Withdraw Funds" button

---

## Quick Test

Want to test it right now? After all 3 steps above:

### Test Sending a Tip:
```bash
# In any terminal (not the validator one!)
solana transfer <ADDRESS_FROM_WEBPAGE> 0.1
```

### Test Owner Features:
1. Click "Select Wallet" on webpage
2. Choose Phantom (install if needed)
3. Connect your wallet
4. You should see the Owner Dashboard!
5. Try withdrawing 0.05 SOL

---

## 🔧 Troubleshooting

### Can't start validator?
```bash
pkill solana-test-validator
solana-test-validator --reset
```

### Tests fail?
```bash
anchor clean
anchor build
anchor test --skip-local-validator
```

### Wallet won't connect?
1. Install Phantom wallet extension
2. Switch to "Localhost" network in Phantom
3. Refresh the page

### Don't see Owner Dashboard?
You need to connect with the wallet that ran the tests.
```bash
solana address  # This is your owner wallet
```
Use this same wallet in Phantom.

---

## 📚 Need More Info?

- **Quick Setup**: See `QUICKSTART.md`
- **Client Details**: See `client/CLIENT_README.md`
- **Project Overview**: See `README.md`
- **Presentation Guide**: See `PRESENTATION_GUIDE.md`

---

## 🎯 Terminal Layout

Here's how your terminals should look:

```
┌─────────────────────────┐
│ Terminal 1              │
│ solana-test-validator   │
│ [Running continuously]  │
└─────────────────────────┘

┌─────────────────────────┐
│ Terminal 2              │
│ anchor test             │
│ [6 passing ✓]           │
└─────────────────────────┘

┌─────────────────────────┐
│ Terminal 3              │
│ npm run dev             │
│ [Server running on      │
│  http://localhost:3000] │
└─────────────────────────┘
```

---

## 💰 Understanding the Flow

1. **Smart Contract** (Rust) runs on Solana blockchain
2. **Local Validator** simulates the blockchain on your computer
3. **Web App** (Next.js) talks to the contract via Solana RPC
4. **Your Wallet** signs transactions to interact with contract

```
You → Wallet → Web App → RPC → Validator → Smart Contract
                  ↓                           ↓
                UI Updates ←─── Reads ───────┘
```

---

## ✅ Success Indicators

You'll know everything is working when:

| Component | Success Sign |
|-----------|-------------|
| Validator | No error messages, running quietly |
| Tests | "6 passing" in green |
| Web App | Page loads at localhost:3000 |
| QR Code | Visible in the center |
| Wallet | Connects without errors |
| Owner View | Shows dashboard with balance |

---

## 🎁 What You Have Now

- ✅ A working smart contract on Solana
- ✅ A beautiful web interface
- ✅ QR code for easy tipping
- ✅ Owner dashboard for withdrawals
- ✅ Complete documentation
- ✅ Ready for your presentation!

---

## 🚀 Next Steps

Once you have it working:

1. **Explore the Code**
   - `programs/tipjar/src/lib.rs` - Smart contract
   - `client/components/TipJar.tsx` - Web UI

2. **Try Things Out**
   - Send multiple tips
   - Withdraw different amounts
   - Connect with different wallets

3. **Customize It**
   - Change colors in `TipJar.tsx`
   - Modify tip amounts
   - Add your own features!

4. **Deploy to Devnet**
   - See `QUICKSTART.md` for devnet setup
   - Share with friends!

---

## 💬 Common First-Time Questions

**Q: Do I need real money?**
A: No! Local testing uses fake SOL. Only mainnet uses real SOL.

**Q: Can I lose money testing?**
A: No! localhost = completely safe, no real blockchain.

**Q: How do I stop everything?**
A: Press Ctrl+C in each terminal window.

**Q: Can other people access it?**
A: Not by default. It's only on your computer.

**Q: What if I close a terminal?**
A: Just re-run that step. Order matters: Validator → Deploy → Web App.

---

## 🎉 Ready? Let's Go!

Run the three steps at the top of this file and you'll be live in 2 minutes!

**Have fun! 🚀**

