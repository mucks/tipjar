# Anchor Smart Contract Quick Reference

## 🚀 Getting Started

```bash
# Create new project
anchor init project_name

# Build
anchor build

# Test (with local validator)
anchor test

# Test (skip starting validator)
anchor test --skip-local-validator

# Deploy
anchor deploy
```

## 📝 Program Structure

```rust
use anchor_lang::prelude::*;

declare_id!("YourProgramIDHere");

#[program]
pub mod my_program {
    use super::*;
    
    pub fn instruction_name(ctx: Context<InstructionAccounts>, arg: u64) -> Result<()> {
        // Your code here
        Ok(())
    }
}

#[derive(Accounts)]
pub struct InstructionAccounts<'info> {
    // Accounts here
}

#[account]
pub struct DataAccount {
    // Fields here
}
```

## 🔑 Common Account Constraints

```rust
#[account(mut)]  // Mutable account
pub account: Account<'info, MyAccount>

#[account(init, payer = user, space = 8 + 32)]  // Initialize new account
pub new_account: Account<'info, MyAccount>

#[account(init, seeds = [b"seed"], bump, payer = user, space = 8 + 32)]  // PDA
pub pda_account: Account<'info, MyAccount>

#[account(mut, seeds = [b"seed"], bump)]  // Verify existing PDA
pub pda_account: Account<'info, MyAccount>

#[account(has_one = owner)]  // Verify field matches account
pub account: Account<'info, MyAccount>

#[account(mut)]  // Signer required
pub signer: Signer<'info>

pub system_program: Program<'info, System>  // System program
```

## 💾 Data Types & Sizes

| Type | Size (bytes) | Example |
|------|--------------|---------|
| `u8` | 1 | `255` |
| `u16` | 2 | `65535` |
| `u32` | 4 | `4294967295` |
| `u64` | 8 | `18446744073709551615` |
| `i8`-`i64` | 1-8 | Signed integers |
| `bool` | 1 | `true`/`false` |
| `Pubkey` | 32 | Account address |
| `String` | 4 + length | Variable |
| `Vec<T>` | 4 + (size × count) | Variable |
| Discriminator | 8 | Auto-added by Anchor |

**Space Calculation:**
```rust
space = 8 (discriminator)
      + 32 (pubkey)
      + 8 (u64)
      + 4 + 50 (String max 50 chars)
```

## 🔐 Security Checklist

- [ ] All accounts have proper constraints
- [ ] Signers use `Signer<'info>` type
- [ ] PDAs use `seeds` and `bump` validation
- [ ] Owner checks with `has_one` constraint
- [ ] Input validation with `require!`
- [ ] Safe math with `.checked_add()`, `.checked_sub()`
- [ ] No uninitialized account access
- [ ] Rent exemption protected

## 💸 SOL Transfers

**Via CPI (Cross-Program Invocation):**
```rust
let cpi_context = CpiContext::new(
    ctx.accounts.system_program.to_account_info(),
    system_program::Transfer {
        from: ctx.accounts.sender.to_account_info(),
        to: ctx.accounts.receiver.to_account_info(),
    },
);
system_program::transfer(cpi_context, amount)?;
```

**Direct Lamport Manipulation:**
```rust
**from_account.try_borrow_mut_lamports()? -= amount;
**to_account.try_borrow_mut_lamports()? += amount;
```

## 🧪 Testing

**Basic Test Structure:**
```javascript
const anchor = require("@coral-xyz/anchor");
const { SystemProgram } = anchor.web3;

describe("program", () => {
  const provider = anchor.AnchorProvider.env();
  anchor.setProvider(provider);
  const program = anchor.workspace.ProgramName;

  it("Test name", async () => {
    const tx = await program.methods
      .instructionName(new anchor.BN(123))
      .accounts({
        account1: publicKey1,
        account2: publicKey2,
        systemProgram: SystemProgram.programId,
      })
      .rpc();
    
    // Fetch account data
    const account = await program.account.accountType.fetch(address);
    console.log(account);
  });
});
```

**PDA Derivation:**
```javascript
const [pda, bump] = anchor.web3.PublicKey.findProgramAddressSync(
  [Buffer.from("seed"), otherPubkey.toBuffer()],
  program.programId
);
```

## ⚠️ Common Errors

| Error | Meaning | Solution |
|-------|---------|----------|
| `A seeds constraint was violated` | PDA seeds don't match | Check seed derivation |
| `A has_one constraint was violated` | Field doesn't match account | Verify account ownership |
| `RequireViolated` | `require!` check failed | Check your validation logic |
| `AccountNotMutable` | Writing to non-mut account | Add `mut` constraint |
| `ConstraintSigner` | Missing signature | Account must be `Signer` |
| `AccountNotEnoughKeys` | Missing account | Check accounts list |

## 🎯 Error Handling

```rust
#[error_code]
pub enum MyError {
    #[msg("Custom error message here")]
    ErrorName,
    #[msg("Another error message")]
    AnotherError,
}

// Usage in code
require!(condition, MyError::ErrorName);
```

## 📊 Useful Commands

```bash
# Solana CLI
solana balance                          # Check balance
solana airdrop 2                        # Get 2 SOL (devnet/testnet)
solana address                          # Show wallet address
solana config get                       # Show config
solana config set --url <RPC_URL>       # Change network

# Anchor
anchor keys list                        # Show program IDs
anchor clean                            # Clean build artifacts
anchor upgrade <PROGRAM_PATH> --program-id <ID>  # Upgrade program

# Networks
mainnet-beta: https://api.mainnet-beta.solana.com
devnet:      https://api.devnet.solana.com
testnet:     https://api.testnet.solana.com
localhost:   http://localhost:8899
```

## 🔗 Important Constants

```rust
LAMPORTS_PER_SOL = 1_000_000_000

// Common Program IDs
System Program:     11111111111111111111111111111111
Token Program:      TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA
Associated Token:   ATokenGPvbdGVxr1b2hvZbsiqW5xWH25efTNsLJA8knL
```

## 💡 Pro Tips

1. **Always use checked math**: `.checked_add()`, `.checked_sub()`, `.checked_mul()`
2. **PDAs for program-owned accounts**: No private key needed
3. **Account size must be exact**: Calculate carefully
4. **Test security cases**: Try to break your own program
5. **Use meaningful error messages**: Helps with debugging
6. **Keep state minimal**: Smaller accounts = lower rent
7. **Version your accounts**: Add version field for upgrades

## 🔍 Debugging

```rust
// Logging in program
msg!("Variable: {}", value);
msg!("Account: {}", account.key());

// In JavaScript tests
console.log(await program.account.myAccount.fetch(address));
```

**View logs:**
```bash
solana logs | grep "Program log"
```

## 📚 Resources

- **Anchor Docs**: https://www.anchor-lang.com/
- **Solana Cookbook**: https://solanacookbook.com/
- **Solana Docs**: https://docs.solana.com/
- **SPL Docs**: https://spl.solana.com/

---

**Save this for quick reference during development! 🚀**

