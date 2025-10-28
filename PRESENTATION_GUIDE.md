# Tipjar Contract - 2 Hour Presentation Guide

## Overview
This guide will help you deliver a comprehensive 2-hour presentation on Rust smart contracts using the Tipjar example.

---

## 🎯 Learning Objectives

By the end of this presentation, attendees will:
- Understand the Solana account model
- Know how to write smart contracts using Anchor framework
- Understand Program Derived Addresses (PDAs)
- Be able to test and deploy Solana programs
- Understand security considerations for smart contracts

---

## 📋 Prerequisites for Attendees

### Required Knowledge
- Basic Rust programming (structs, enums, error handling)
- Command line familiarity
- Basic blockchain concepts (accounts, transactions)

### Software Setup (Share Before Presentation)
```bash
# Install Rust
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

# Install Solana CLI
sh -c "$(curl -sSfL https://release.solana.com/stable/install)"

# Install Anchor CLI
cargo install --git https://github.com/coral-xyz/anchor avm --locked --force
avm install latest
avm use latest

# Verify installations
rustc --version
solana --version
anchor --version
```

---

## 🎬 Presentation Structure

### **PART 1: Introduction (20 minutes)** ⏰ 0:00 - 0:20

#### Slide 1: Welcome & Agenda (2 min)
- Introduction
- Overview of the 2-hour session
- Brief overview of what we'll build

#### Slide 2: What is Solana? (5 min)
**Key Points:**
- High-performance blockchain (65,000 TPS)
- Low transaction fees (~$0.00025)
- Proof of History + Proof of Stake
- Programs (smart contracts) written in Rust

**Comparison Table:**
| Feature | Solana | Ethereum |
|---------|--------|----------|
| TPS | 65,000 | 15-30 |
| Finality | ~400ms | 6+ minutes |
| Cost/tx | $0.00025 | $1-50+ |
| Language | Rust, C, C++ | Solidity |

#### Slide 3: Solana's Account Model (8 min)
**Key Concept:** Everything is an account!

```
┌─────────────────────────────┐
│  Account                    │
├─────────────────────────────┤
│ • Lamports (balance)        │
│ • Owner (program)           │
│ • Data (bytes)              │
│ • Executable flag           │
│ • Rent epoch                │
└─────────────────────────────┘
```

**Types of Accounts:**
1. **Wallet Accounts** - Hold SOL, owned by System Program
2. **Program Accounts** - Hold executable code
3. **Data Accounts** - Hold state, owned by programs

**Demo:** Show Solana Explorer with an example account

#### Slide 4: What is Anchor? (5 min)
**Key Points:**
- Framework for Solana development (like Ruby on Rails for Rust)
- Handles serialization/deserialization
- Built-in security checks
- IDL generation for clients
- Reduces boilerplate by ~80%

**Code Comparison:**
Show Native Solana vs Anchor code side by side

---

### **PART 2: Tipjar Deep Dive (40 minutes)** ⏰ 0:20 - 1:00

#### Slide 5: Project Overview (3 min)
**What We're Building:**
- A digital tip jar
- Anyone can send tips (SOL)
- Only owner can withdraw
- Tracks total tips and tip count

**Real-World Use Cases:**
- Content creator donations
- Service tips (restaurants, delivery)
- Community fund collection

#### Slide 6: Project Structure (3 min)
```
tipjar/
├── programs/
│   └── tipjar/
│       └── src/
│           └── lib.rs          ← Our smart contract
├── tests/
│   └── tipjar.js              ← Test suite
├── Anchor.toml                ← Config
└── Cargo.toml                 ← Rust dependencies
```

**Live Demo:** Navigate through the project structure

#### Slide 7: Program ID & Imports (2 min)
```rust
use anchor_lang::prelude::*;
use anchor_lang::system_program;

declare_id!("9SsavCqnPP6NLu6sbA8YsDDN23hQrXUKuPXZgp1C1ojQ");
```

**Explain:**
- `declare_id!` macro - unique identifier for our program
- Gets generated when you build
- Changes when you deploy to different networks

#### Slide 8: Data Structure (5 min)
```rust
#[account]
pub struct Tipjar {
    pub owner: Pubkey,      // 32 bytes
    pub total_tips: u64,    // 8 bytes
    pub tip_count: u64,     // 8 bytes
}
```

**Key Concepts:**
- `#[account]` macro adds 8-byte discriminator
- Total space: 8 + 32 + 8 + 8 = 56 bytes
- All data must be declared upfront (no dynamic sizing)
- Pubkey is 32 bytes (base58 encoded address)

**Interactive:** Ask audience to calculate space for different structs

#### Slide 9: Initialize Instruction (8 min)
**Walk through the code:**

```rust
pub fn initialize(ctx: Context<Initialize>) -> Result<()> {
    let tipjar = &mut ctx.accounts.tipjar;
    tipjar.owner = ctx.accounts.owner.key();
    tipjar.total_tips = 0;
    tipjar.tip_count = 0;
    
    msg!("Tipjar initialized!");
    msg!("Owner: {}", tipjar.owner);
    
    Ok(())
}
```

**Account Constraints:**
```rust
#[derive(Accounts)]
pub struct Initialize<'info> {
    #[account(
        init,                       // Create new account
        payer = owner,              // Who pays for creation
        space = 8 + 32 + 8 + 8,    // Account size
        seeds = [b"tipjar"],        // PDA seeds
        bump                        // Find valid bump
    )]
    pub tipjar: Account<'info, Tipjar>,
    
    #[account(mut)]
    pub owner: Signer<'info>,
    
    pub system_program: Program<'info, System>,
}
```

**Key Points:**
- `init` - Creates and initializes account
- `payer` - Account that pays for rent
- `space` - Account size (must be exact)
- `seeds` + `bump` - Creates a PDA
- `Signer` - Requires transaction signature

#### Slide 10: Program Derived Addresses (PDAs) (7 min)
**Why PDAs?**
1. Deterministic addresses (no private keys)
2. Program can sign for them
3. Easy to find (no need to store address)

**How PDAs Work:**
```
seeds = ["tipjar"] + program_id → PDA address
```

**Visual Diagram:**
```
Input Seeds: ["tipjar"]
      ↓
Program ID: 9Ssav...1ojQ
      ↓
SHA256 Hash
      ↓
If on curve? → Try bump 255, 254, 253...
      ↓
First off-curve = PDA ✓
```

**Code Example:**
```javascript
const [tipjarPda, bump] = PublicKey.findProgramAddressSync(
  [Buffer.from("tipjar")],
  program.programId
);
```

**Interactive:** Explain why PDAs must be off the Ed25519 curve

#### Slide 11: Send Tip Instruction (6 min)
```rust
pub fn send_tip(ctx: Context<SendTip>, amount: u64) -> Result<()> {
    require!(amount > 0, TipjarError::InvalidAmount);
    
    // CPI to System Program
    let cpi_context = CpiContext::new(
        ctx.accounts.system_program.to_account_info(),
        system_program::Transfer {
            from: ctx.accounts.tipper.to_account_info(),
            to: ctx.accounts.tipjar.to_account_info(),
        },
    );
    system_program::transfer(cpi_context, amount)?;
    
    // Update state
    let tipjar = &mut ctx.accounts.tipjar;
    tipjar.total_tips = tipjar.total_tips.checked_add(amount).unwrap();
    tipjar.tip_count += 1;
    
    Ok(())
}
```

**Key Concepts:**
- `require!` macro - validation before execution
- CPI (Cross-Program Invocation) - calling other programs
- `checked_add` - safe math (prevents overflow)
- State updates happen after transfer

**Account Constraints:**
```rust
#[derive(Accounts)]
pub struct SendTip<'info> {
    #[account(
        mut,                    // Can modify
        seeds = [b"tipjar"],    // Verify PDA
        bump                    // Verify bump
    )]
    pub tipjar: Account<'info, Tipjar>,
    
    #[account(mut)]
    pub tipper: Signer<'info>,
    
    pub system_program: Program<'info, System>,
}
```

#### Slide 12: Withdraw Instruction (6 min)
```rust
pub fn withdraw(ctx: Context<Withdraw>, amount: u64) -> Result<()> {
    let tipjar = &ctx.accounts.tipjar;
    
    require!(amount > 0, TipjarError::InvalidAmount);
    
    // Calculate available balance (minus rent)
    let rent = Rent::get()?.minimum_balance(
        tipjar.to_account_info().data_len()
    );
    let available_balance = tipjar
        .to_account_info()
        .lamports()
        .checked_sub(rent)
        .unwrap();
    
    require!(amount <= available_balance, TipjarError::InsufficientFunds);
    
    // Transfer lamports
    **tipjar.to_account_info().try_borrow_mut_lamports()? -= amount;
    **ctx.accounts.owner.to_account_info().try_borrow_mut_lamports()? += amount;
    
    Ok(())
}
```

**Key Concepts:**
- Rent exemption - accounts must maintain minimum balance
- Direct lamport manipulation (no CPI needed)
- `has_one = owner` constraint ensures only owner can call

**Account Constraints:**
```rust
#[derive(Accounts)]
pub struct Withdraw<'info> {
    #[account(
        mut,
        seeds = [b"tipjar"],
        bump,
        has_one = owner         // Security check!
    )]
    pub tipjar: Account<'info, Tipjar>,
    
    #[account(mut)]
    pub owner: Signer<'info>,
}
```

---

### **PART 3: Testing & Demo (30 minutes)** ⏰ 1:00 - 1:30

#### Slide 13: Test Setup (5 min)
```javascript
const anchor = require("@coral-xyz/anchor");
const provider = anchor.AnchorProvider.env();
anchor.setProvider(provider);

const program = anchor.workspace.Tipjar;

// Derive PDA
const [tipjarPda] = anchor.web3.PublicKey.findProgramAddressSync(
  [Buffer.from("tipjar")],
  program.programId
);
```

**Explain:**
- Anchor workspace automatically loads compiled program
- Provider connects to local validator
- PDA derivation on client side

#### Slide 14: Writing Tests (10 min)
**Live Coding:** Walk through each test

1. **Test: Initialize**
```javascript
it("Initializes the tipjar", async () => {
  const tx = await program.methods
    .initialize()
    .accounts({
      tipjar: tipjarPda,
      owner: provider.wallet.publicKey,
      systemProgram: SystemProgram.programId,
    })
    .rpc();
    
  const tipjarAccount = await program.account.tipjar.fetch(tipjarPda);
  console.log("Owner:", tipjarAccount.owner.toString());
});
```

2. **Test: Send Tip**
3. **Test: Withdraw**
4. **Test: Security (non-owner cannot withdraw)**

#### Slide 15: Running the Tests (15 min)
**Live Demo:**

```bash
# Terminal 1: Start local validator
solana-test-validator

# Terminal 2: Run tests
cd tipjar
anchor test --skip-local-validator
```

**Expected Output:**
```
tipjar
  ✓ Initializes the tipjar
  ✓ Sends a tip to the tipjar
  ✓ Sends multiple tips
  ✓ Owner withdraws from the tipjar
  ✓ Fails when non-owner tries to withdraw
  ✓ Fails when trying to send 0 tip

6 passing (2s)
```

**Interactive:**
- Show account balances before/after
- Demonstrate transactions on local explorer
- Show logs from `msg!` calls

---

### **PART 4: Security & Best Practices (20 minutes)** ⏰ 1:30 - 1:50

#### Slide 16: Common Vulnerabilities (8 min)
**1. Missing Signer Checks**
```rust
// BAD - Anyone can call
pub owner: AccountInfo<'info>

// GOOD - Must sign transaction
pub owner: Signer<'info>
```

**2. Missing Ownership Checks**
```rust
// BAD - No validation
pub tipjar: AccountInfo<'info>

// GOOD - Validates account type
pub tipjar: Account<'info, Tipjar>

// BETTER - Validates owner matches
#[account(has_one = owner)]
pub tipjar: Account<'info, Tipjar>
```

**3. Integer Overflow**
```rust
// BAD - Can overflow
tipjar.total_tips += amount;

// GOOD - Checked math
tipjar.total_tips = tipjar.total_tips.checked_add(amount).unwrap();
```

**4. Reinitialization Attack**
```rust
// Protected by init constraint
#[account(init, ...)]  // Can only be called once
```

#### Slide 17: Anchor Security Features (5 min)
**Built-in Protections:**

1. **Account Discrimination**
   - 8-byte discriminator prevents type confusion
   - Automatically checked by Anchor

2. **Rent Protection**
   - Anchor handles rent exemption
   - Prevents account deletion

3. **PDA Validation**
   - Seeds and bump automatically verified
   - Prevents spoofing

4. **Signer Validation**
   - `Signer<'info>` enforces signature
   - Compile-time checks

#### Slide 18: Best Practices (7 min)
**1. Input Validation**
```rust
require!(amount > 0, TipjarError::InvalidAmount);
require!(amount <= max_amount, TipjarError::AmountTooLarge);
```

**2. Check-Effects-Interactions Pattern**
```rust
// 1. Checks
require!(amount > 0, TipjarError::InvalidAmount);

// 2. Effects (state changes)
tipjar.total_tips += amount;

// 3. Interactions (external calls)
system_program::transfer(cpi_context, amount)?;
```

**3. Use Explicit Account Types**
```rust
// Instead of AccountInfo, use:
Account<'info, Tipjar>        // For program accounts
Program<'info, System>        // For programs
Signer<'info>                 // For signers
```

**4. Comprehensive Testing**
- Test happy paths
- Test edge cases (0 amounts, max values)
- Test security (unauthorized access)
- Test race conditions

**5. Gas Optimization**
- Minimize account size
- Use efficient data structures
- Batch operations when possible

---

### **PART 5: Deployment & Next Steps (10 minutes)** ⏰ 1:50 - 2:00

#### Slide 19: Deploying to Devnet (5 min)
**Live Demo:**

```bash
# Configure for devnet
solana config set --url https://api.devnet.solana.com

# Get some devnet SOL
solana airdrop 2

# Build program
anchor build

# Deploy to devnet
anchor deploy

# Update program ID in code
anchor keys list
# Copy the program ID to lib.rs and Anchor.toml

# Rebuild and redeploy
anchor build
anchor deploy

# Run tests against devnet
anchor test --provider.cluster devnet
```

#### Slide 20: Next Steps & Resources (5 min)
**Extend the Tipjar:**
1. Add tipping history (who tipped, when, how much)
2. Add multiple tip jars per owner
3. Add automatic distribution to multiple addresses
4. Add tip goals and notifications

**More Contract Ideas for Your Presentation:**
1. **Voting System** - Governance and DAO basics
2. **Token Vault** - SPL tokens and token accounts
3. **Escrow** - Multi-party transactions
4. **NFT Minting** - Metadata and Metaplex

**Learning Resources:**
- [Anchor Book](https://book.anchor-lang.com/)
- [Solana Cookbook](https://solanacookbook.com/)
- [Solana Program Library](https://spl.solana.com/)
- [Anchor Examples](https://github.com/coral-xyz/anchor/tree/master/tests)

**Community:**
- Solana Discord
- Solana Stack Exchange
- Anchor GitHub Discussions

---

## 🎤 Presentation Tips

### Before the Session
- [ ] Test all code examples
- [ ] Prepare local validator
- [ ] Have Solana Explorer bookmarked
- [ ] Prepare backup slides for common questions
- [ ] Test screen sharing setup

### During the Session
- **Use Two Monitors**: Code on one, slides on another
- **Live Coding**: Keep it real - bugs happen, show how to debug
- **Interactive**: Ask questions, poll the audience
- **Pace Check**: After each section, ask if questions
- **Breaks**: None scheduled, but watch energy levels

### Common Questions to Prepare For
1. "Why Rust instead of Solidity?"
2. "What's the cost to deploy?"
3. "How do I debug Solana programs?"
4. "What about upgradability?"
5. "How do PDAs compare to CREATE2 in Ethereum?"
6. "What happens if the account runs out of rent?"

---

## 🧰 Troubleshooting Guide

### Common Issues
**Issue:** Test validator won't start
```bash
# Solution: Kill existing validator
pkill solana-test-validator
solana-test-validator --reset
```

**Issue:** Anchor build fails
```bash
# Solution: Clean and rebuild
anchor clean
rm -rf target
anchor build
```

**Issue:** Transaction simulation failed
- Usually means account constraints failed
- Check: PDA derivation, signer requirements, account ownership

---

## 📊 Timing Checkpoints

| Time | Section | Key Deliverable |
|------|---------|----------------|
| 0:20 | Part 1 Complete | Audience understands Solana basics |
| 0:40 | Data structure + Initialize | Understand PDAs and account creation |
| 1:00 | All instructions covered | Can read and understand the contract |
| 1:30 | Tests running | Can test and verify behavior |
| 1:50 | Security covered | Understand vulnerabilities |
| 2:00 | Deployed to devnet | Can deploy their own contracts |

---

## 🎯 Success Metrics

After your presentation, attendees should be able to:
- [ ] Explain the Solana account model
- [ ] Create a new Anchor project
- [ ] Write basic instructions (functions)
- [ ] Use PDAs effectively
- [ ] Write and run tests
- [ ] Identify common security issues
- [ ] Deploy to devnet

---

**Good luck with your presentation! 🚀**

Feel free to adapt this guide to your teaching style and audience level. The most important thing is that your enthusiasm for Solana development comes through!

