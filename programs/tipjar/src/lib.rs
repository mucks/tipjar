use anchor_lang::prelude::*;
use anchor_lang::system_program;

declare_id!("9SsavCqnPP6NLu6sbA8YsDDN23hQrXUKuPXZgp1C1ojQ");

#[program]
pub mod tipjar {
    use super::*;

    /// Initialize the tipjar with an owner
    /// The owner is the only one who can withdraw tips
    pub fn initialize(ctx: Context<Initialize>) -> Result<()> {
        let tipjar = &mut ctx.accounts.tipjar;
        tipjar.owner = ctx.accounts.owner.key();
        tipjar.total_tips = 0;
        tipjar.tip_count = 0;

        msg!("Tipjar initialized!");
        msg!("Owner: {}", tipjar.owner);

        Ok(())
    }

    /// Send a tip to the tipjar
    /// Anyone can call this function to send SOL to the tipjar
    pub fn send_tip(ctx: Context<SendTip>, amount: u64) -> Result<()> {
        require!(amount > 0, TipjarError::InvalidAmount);

        // Transfer SOL from tipper to tipjar account
        let cpi_context = CpiContext::new(
            ctx.accounts.system_program.to_account_info(),
            system_program::Transfer {
                from: ctx.accounts.tipper.to_account_info(),
                to: ctx.accounts.tipjar.to_account_info(),
            },
        );
        system_program::transfer(cpi_context, amount)?;

        // Update tipjar state
        let tipjar = &mut ctx.accounts.tipjar;
        tipjar.total_tips = tipjar.total_tips.checked_add(amount).unwrap();
        tipjar.tip_count += 1;

        msg!("Tip received!");
        msg!("Amount: {} lamports", amount);
        msg!("Tipper: {}", ctx.accounts.tipper.key());
        msg!("Total tips: {} lamports", tipjar.total_tips);
        msg!("Total tip count: {}", tipjar.tip_count);

        Ok(())
    }

    /// Withdraw tips from the tipjar
    /// Only the owner can withdraw
    pub fn withdraw(ctx: Context<Withdraw>, amount: u64) -> Result<()> {
        let tipjar = &ctx.accounts.tipjar;

        require!(amount > 0, TipjarError::InvalidAmount);

        // Get the current balance of the tipjar (excluding rent)
        let rent = Rent::get()?.minimum_balance(tipjar.to_account_info().data_len());
        let available_balance = tipjar
            .to_account_info()
            .lamports()
            .checked_sub(rent)
            .unwrap();

        require!(amount <= available_balance, TipjarError::InsufficientFunds);

        // Transfer SOL from tipjar to owner
        **tipjar.to_account_info().try_borrow_mut_lamports()? -= amount;
        **ctx
            .accounts
            .owner
            .to_account_info()
            .try_borrow_mut_lamports()? += amount;

        msg!("Withdrawal successful!");
        msg!("Amount: {} lamports", amount);
        msg!("Owner: {}", ctx.accounts.owner.key());
        msg!("Remaining balance: {} lamports", available_balance - amount);

        Ok(())
    }
}

// Account validation structs

#[derive(Accounts)]
pub struct Initialize<'info> {
    #[account(
        init,
        payer = owner,
        space = 8 + 32 + 8 + 8, // discriminator + pubkey + u64 + u64
        seeds = [b"tipjar"],
        bump
    )]
    pub tipjar: Account<'info, Tipjar>,

    #[account(mut)]
    pub owner: Signer<'info>,

    pub system_program: Program<'info, System>,
}

#[derive(Accounts)]
pub struct SendTip<'info> {
    #[account(
        mut,
        seeds = [b"tipjar"],
        bump
    )]
    pub tipjar: Account<'info, Tipjar>,

    #[account(mut)]
    pub tipper: Signer<'info>,

    pub system_program: Program<'info, System>,
}

#[derive(Accounts)]
pub struct Withdraw<'info> {
    #[account(
        mut,
        seeds = [b"tipjar"],
        bump,
        has_one = owner
    )]
    pub tipjar: Account<'info, Tipjar>,

    #[account(mut)]
    pub owner: Signer<'info>,
}

// Data structures

#[account]
pub struct Tipjar {
    pub owner: Pubkey,   // The owner who can withdraw tips
    pub total_tips: u64, // Total amount of tips received (in lamports)
    pub tip_count: u64,  // Number of tips received
}

// Error codes

#[error_code]
pub enum TipjarError {
    #[msg("Amount must be greater than 0")]
    InvalidAmount,
    #[msg("Insufficient funds in tipjar")]
    InsufficientFunds,
}
