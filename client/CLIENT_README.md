# Tipjar Client - Next.js Web Application

A beautiful, modern web interface for the Solana Tipjar smart contract.

## 🎨 Features

### For Tippers (Public Users)
- 📱 **QR Code Display** - Scan with any Solana wallet to send tips
- 📊 **Live Statistics** - See total tips and tip count
- 📋 **Copy Address** - Easy one-click address copying
- 🎯 **Clean UI** - Beautiful gradient design with intuitive UX

### For Owners
- 👑 **Owner Dashboard** - Automatic detection when owner wallet connects
- 💰 **Balance Display** - See total tips received and available balance
- 🏦 **Withdraw Funds** - Simple form to withdraw any amount
- 📈 **Statistics** - Track total tips and tip count
- ✅ **Real-time Updates** - Balance updates after each transaction

## 🚀 Getting Started

### Prerequisites
- Node.js 18+ installed
- A Solana wallet (Phantom recommended)
- The tipjar contract deployed (see parent directory)

### Installation

```bash
# Navigate to client directory
cd client

# Install dependencies (already done)
npm install

# Start development server
npm run dev
```

The app will be available at [http://localhost:3000](http://localhost:3000)

## 🔧 Configuration

### Network Configuration

Edit `lib/config.ts` to change the Solana network:

```typescript
export const SOLANA_NETWORK = "http://127.0.0.1:8899"; // Local
// export const SOLANA_NETWORK = "https://api.devnet.solana.com"; // Devnet
// export const SOLANA_NETWORK = "https://api.mainnet-beta.solana.com"; // Mainnet
```

Or set environment variable:
```bash
NEXT_PUBLIC_SOLANA_NETWORK=https://api.devnet.solana.com npm run dev
```

### Program ID

If you redeploy the contract and get a new Program ID, update it in:
- `lib/anchor-client.ts` - Change the `PROGRAM_ID` constant
- Make sure the IDL file is updated: `lib/tipjar.json`

## 📱 How It Works

### User Flow

1. **Visit the Site**
   - User sees the tipjar interface
   - QR code is displayed for easy tipping

2. **Connect Wallet (Optional for Viewing)**
   - Click "Select Wallet" to connect
   - Choose Phantom or another Solana wallet
   - Approve the connection

3. **Two Different Views:**

   **Public View (Non-Owner):**
   - See QR code for tipping
   - View total tips and tip count
   - Copy tipjar address
   - Send tips by scanning QR or copying address

   **Owner View (When Owner Connects):**
   - See dashboard with total tips received
   - View available balance
   - Enter withdrawal amount
   - Click "Withdraw Funds" to receive SOL
   - "Withdraw All Available" button for quick full withdrawal

## 🔐 Security Features

- **Owner Authentication**: Automatically detects owner wallet
- **Wallet Signature Required**: All transactions require wallet approval
- **Rent Protection**: Prevents withdrawing the rent-exempt balance
- **Input Validation**: Validates withdrawal amounts
- **Error Handling**: Clear error messages for users

## 🎨 UI Components

### TipJar Component (`components/TipJar.tsx`)
Main component with all the logic and UI:
- Wallet connection handling
- Owner detection
- Balance fetching
- Withdraw functionality
- QR code generation
- Responsive design

### WalletContextProvider (`components/WalletContextProvider.tsx`)
Wraps the app with Solana wallet adapter:
- Manages wallet connections
- Provides wallet context to all components
- Supports multiple wallet types

## 📦 Dependencies

### Core Dependencies
- `next` - React framework
- `react` & `react-dom` - UI library
- `@coral-xyz/anchor` - Anchor framework client
- `@solana/web3.js` - Solana JavaScript API
- `@solana/wallet-adapter-react` - Wallet adapter hooks
- `@solana/wallet-adapter-react-ui` - Wallet UI components
- `@solana/wallet-adapter-wallets` - Wallet implementations
- `qrcode.react` - QR code generation
- `tailwindcss` - Styling

## 🔄 Development Workflow

### Running Locally

1. **Start Local Validator** (in another terminal):
```bash
cd .. # Back to tipjar root
solana-test-validator
```

2. **Deploy Contract** (if not already deployed):
```bash
anchor build
anchor deploy
```

3. **Copy IDL** (if changed):
```bash
cp target/idl/tipjar.json client/lib/
```

4. **Start Client**:
```bash
cd client
npm run dev
```

5. **Connect Wallet**:
   - Open Phantom wallet
   - Switch to localhost network
   - Connect to the app

### Testing Owner Features

To test owner features, you need to connect with the wallet that initialized the tipjar:

```bash
# Get your wallet address
solana address

# Use this wallet to initialize the tipjar (if not already done)
anchor test

# Connect with this same wallet in the UI to see owner dashboard
```

### Sending Test Tips

You can send tips in several ways:

1. **Via QR Code**: Scan with mobile wallet (if on same network)
2. **Via Wallet**: Copy the tipjar address and send from any wallet
3. **Via CLI**:
```bash
solana transfer <TIPJAR_ADDRESS> 0.1
```

## 🐛 Troubleshooting

### "Failed to fetch tipjar account"
- Make sure the tipjar is initialized
- Run `anchor test` in the parent directory
- Check network configuration

### "Transaction simulation failed"
- Ensure you have enough SOL for transaction fees
- Check that the tipjar has been initialized
- Verify you're connected to the correct network

### Wallet Not Connecting
- Make sure Phantom or your wallet is installed
- Check that your wallet is on the correct network (localhost/devnet)
- Try refreshing the page

### Owner Features Not Showing
- Ensure you're connected with the wallet that initialized the tipjar
- Check browser console for errors
- Verify the tipjar owner address matches your wallet

### QR Code Not Working
- Ensure your mobile wallet supports Solana Pay
- Check that both devices are on networks that can communicate
- Try copying the address manually

## 📱 Mobile Support

The UI is fully responsive and works on:
- Desktop browsers
- Tablets
- Mobile browsers
- Mobile wallets (for scanning QR codes)

## 🎨 Customization

### Changing Colors

Edit the gradient in `components/TipJar.tsx`:

```tsx
// Change the background gradient
className="min-h-screen bg-gradient-to-br from-purple-500 via-pink-500 to-red-500"

// Change button colors
className="!bg-gradient-to-r !from-purple-600 !to-pink-600"
```

### Changing Default Tip Amount

Edit the QR code generation in `TipJar.tsx`:

```tsx
const generatePaymentUrl = () => {
  return `solana:${tipjarPDA.toBase58()}?amount=0.5`; // Change 0.5 to desired amount
};
```

### Adding More Wallets

Edit `components/WalletContextProvider.tsx`:

```tsx
import { PhantomWalletAdapter, SolflareWalletAdapter } from "@solana/wallet-adapter-wallets";

const wallets = useMemo(
  () => [
    new PhantomWalletAdapter(),
    new SolflareWalletAdapter(),
    // Add more wallet adapters here
  ],
  []
);
```

## 🚀 Deployment

### Deploy to Vercel

```bash
# Install Vercel CLI
npm i -g vercel

# Deploy
vercel

# Set environment variable for production
vercel env add NEXT_PUBLIC_SOLANA_NETWORK
# Enter: https://api.mainnet-beta.solana.com (or devnet)
```

### Deploy to Other Platforms

The app is a standard Next.js app and can be deployed to:
- Vercel (recommended)
- Netlify
- AWS Amplify
- Railway
- Any platform supporting Next.js

Make sure to set the `NEXT_PUBLIC_SOLANA_NETWORK` environment variable!

## 📊 Production Checklist

Before deploying to mainnet:

- [ ] Update `SOLANA_NETWORK` to mainnet RPC
- [ ] Update `PROGRAM_ID` to mainnet deployment
- [ ] Update IDL file with mainnet deployment
- [ ] Test thoroughly on devnet first
- [ ] Consider adding analytics
- [ ] Add proper error logging
- [ ] Set up monitoring for contract
- [ ] Add rate limiting if needed
- [ ] Consider adding transaction history
- [ ] Implement proper loading states
- [ ] Add transaction confirmations

## 🔗 Related Files

- `../programs/tipjar/src/lib.rs` - Smart contract source
- `../tests/tipjar.js` - Contract tests
- `lib/tipjar.json` - Generated IDL from contract
- `lib/anchor-client.ts` - Anchor program client setup

## 💡 Future Enhancements

Ideas for extending the client:

1. **Transaction History**
   - Show recent tips
   - Display tipper addresses (if you add them to contract)

2. **Notifications**
   - Real-time tip notifications
   - Email/SMS alerts for owners

3. **Multi-Tipjar Support**
   - Create multiple tipjars
   - Switch between them

4. **Analytics Dashboard**
   - Charts showing tips over time
   - Average tip amount
   - Most generous tippers

5. **Social Features**
   - Share tipjar QR on social media
   - Thank you messages
   - Tip leaderboard

6. **Payment Request**
   - Generate custom tip amounts
   - Add messages with tips

## 🎓 Learning Resources

- [Next.js Documentation](https://nextjs.org/docs)
- [Solana Web3.js](https://solana-labs.github.io/solana-web3.js/)
- [Anchor Documentation](https://www.anchor-lang.com/)
- [Solana Wallet Adapter](https://github.com/anza-xyz/wallet-adapter)
- [Solana Pay](https://solanapay.com/)

## 🙏 Support

If you encounter issues:
1. Check the browser console for errors
2. Verify network configuration
3. Ensure contract is deployed and initialized
4. Try on a different network (local → devnet)

---

**Enjoy your Solana Tipjar! 🎉**

