# Tipjar Smart Contract

A simple yet comprehensive Solana smart contract built with Anchor framework that demonstrates fundamental blockchain concepts.

## 🎯 What is a Tipjar?

A tipjar is like a digital tip jar you'd see at a coffee shop - anyone can add tips (SOL), but only the owner can withdraw them. This contract demonstrates:

- **Account initialization** with Program Derived Addresses (PDAs)
- **SOL transfers** between accounts
- **Access control** (only owner can withdraw)
- **State management** (tracking tips and tip count)
- **Error handling** (custom errors)

## 🏗️ Contract Architecture

### Program ID
```
9SsavCqnPP6NLu6sbA8YsDDN23hQrXUKuPXZgp1C1ojQ
```

### Accounts

#### Tipjar Account (PDA)
- **Seeds**: `["tipjar"]`
- **Space**: 56 bytes (8 discriminator + 32 pubkey + 8 u64 + 8 u64)
- **Fields**:
  - `owner`: Pubkey - The account that can withdraw tips
  - `total_tips`: u64 - Total lamports received
  - `tip_count`: u64 - Number of tips received

## 📚 Instructions

### 1. Initialize
Creates the tipjar account and sets the owner.

**Accounts:**
- `tipjar` - The PDA account to initialize (writable)
- `owner` - The future owner of the tipjar (signer, writable)
- `system_program` - Solana system program

**Parameters:** None

**Example:**
```rust
pub fn initialize(ctx: Context<Initialize>) -> Result<()>
```

### 2. Send Tip
Allows anyone to send SOL to the tipjar.

**Accounts:**
- `tipjar` - The PDA account receiving tips (writable)
- `tipper` - The account sending the tip (signer, writable)
- `system_program` - Solana system program

**Parameters:**
- `amount: u64` - Amount in lamports to tip

**Example:**
```rust
pub fn send_tip(ctx: Context<SendTip>, amount: u64) -> Result<()>
```

### 3. Withdraw
Allows the owner to withdraw tips from the jar.

**Accounts:**
- `tipjar` - The PDA account (writable)
- `owner` - The owner account (signer, writable)

**Parameters:**
- `amount: u64` - Amount in lamports to withdraw

**Example:**
```rust
pub fn withdraw(ctx: Context<Withdraw>, amount: u64) -> Result<()>
```

## 🔐 Security Features

1. **PDA (Program Derived Address)**: The tipjar account is a PDA, meaning:
   - It's deterministically derived from the program ID and seeds
   - Only the program can sign for it
   - Users can easily find it without storing addresses

2. **Owner Validation**: The `has_one = owner` constraint ensures only the designated owner can withdraw

3. **Rent Protection**: Withdrawals protect the rent-exempt balance to keep the account alive

4. **Amount Validation**: Both tip and withdraw amounts must be greater than 0

## 🧪 Testing

The test suite demonstrates all functionality:

```bash
# Build the program
anchor build

# Run tests (requires local validator)
anchor test
```

### Test Cases
1. ✅ Initialize the tipjar
2. ✅ Send a tip
3. ✅ Send multiple tips
4. ✅ Owner withdraws from tipjar
5. ✅ Non-owner cannot withdraw (security test)
6. ✅ Cannot send 0 tip (validation test)

## 🚀 Deployment

```bash
# Start local validator
solana-test-validator

# In another terminal, build and deploy
anchor build
anchor deploy

# Update program ID in lib.rs and Anchor.toml
anchor keys list

# Rebuild with new program ID
anchor build
anchor deploy
```

## 💡 Key Concepts for Presentation

### 1. Program Derived Addresses (PDAs)
```rust
#[account(
    init,
    seeds = [b"tipjar"],
    bump
)]
```
- PDAs are accounts owned by programs (not users)
- Derived deterministically from seeds + program ID
- No private key exists for PDAs
- Program can "sign" for its PDAs

### 2. CPI (Cross-Program Invocation)
```rust
let cpi_context = CpiContext::new(
    ctx.accounts.system_program.to_account_info(),
    system_program::Transfer {
        from: ctx.accounts.tipper.to_account_info(),
        to: ctx.accounts.tipjar.to_account_info(),
    },
);
system_program::transfer(cpi_context, amount)?;
```
- Programs can call other programs
- Used here to invoke System Program's transfer instruction

### 3. Account Constraints
```rust
#[account(
    mut,
    seeds = [b"tipjar"],
    bump,
    has_one = owner
)]
```
- `mut`: Account can be modified
- `seeds` + `bump`: Verify PDA derivation
- `has_one`: Verify field matches account

### 4. Rent Exemption
```rust
let rent = Rent::get()?.minimum_balance(tipjar.to_account_info().data_len());
let available_balance = tipjar.to_account_info().lamports().checked_sub(rent).unwrap();
```
- All accounts must maintain minimum balance for rent
- Protects account from being deleted

## 📊 Presentation Flow (2 Hours)

### Part 1: Introduction (20 min)
- What is Solana?
- What is Anchor?
- Overview of smart contracts

### Part 2: Tipjar Contract Deep Dive (40 min)
- Walk through the code structure
- Explain each instruction
- Discuss PDAs and account model
- Show the test cases

### Part 3: Hands-On Demo (30 min)
- Build and deploy locally
- Run tests
- Interact with the contract

### Part 4: Best Practices & Security (20 min)
- Common pitfalls
- Security considerations
- Gas optimization

### Part 5: Q&A (10 min)

## 📖 Resources

- [Anchor Documentation](https://www.anchor-lang.com/)
- [Solana Cookbook](https://solanacookbook.com/)
- [Solana Program Library](https://spl.solana.com/)

## 🔗 Project Structure

```
tipjar/
├── programs/
│   └── tipjar/
│       └── src/
│           └── lib.rs          # Main contract code
├── tests/
│   └── tipjar.js              # Test suite
├── Anchor.toml                # Anchor configuration
└── README.md                  # This file
```

## 💰 Understanding Lamports

- 1 SOL = 1,000,000,000 lamports
- Lamports are the smallest unit of SOL (like satoshis for Bitcoin)
- All calculations in the contract use lamports

## 🎓 Learning Outcomes

After studying this contract, you'll understand:
- How to structure an Anchor program
- How to use PDAs for deterministic addresses
- How to transfer SOL between accounts
- How to implement access control
- How to write comprehensive tests
- How to handle errors properly

---

**Happy Learning! 🚀**

