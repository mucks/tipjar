const anchor = require("@coral-xyz/anchor");
const { SystemProgram, LAMPORTS_PER_SOL } = anchor.web3;

describe("tipjar", () => {
  // Configure the client to use the local cluster.
  const provider = anchor.AnchorProvider.env();
  anchor.setProvider(provider);

  const program = anchor.workspace.Tipjar;

  // Derive the tipjar PDA
  const [tipjarPda] = anchor.web3.PublicKey.findProgramAddressSync(
    [Buffer.from("tipjar")],
    program.programId
  );

  it("Initializes the tipjar", async () => {
    try {
      const tx = await program.methods
        .initialize()
        .accounts({
          tipjar: tipjarPda,
          owner: provider.wallet.publicKey,
          systemProgram: SystemProgram.programId,
        })
        .rpc();

      console.log("✅ Tipjar initialized successfully!");
      console.log("Transaction signature:", tx);

      // Fetch and display the tipjar account
      const tipjarAccount = await program.account.tipjar.fetch(tipjarPda);
      console.log("\nTipjar Account:");
      console.log("  Owner:", tipjarAccount.owner.toString());
      console.log("  Total Tips:", tipjarAccount.totalTips.toString(), "lamports");
      console.log("  Tip Count:", tipjarAccount.tipCount.toString());
    } catch (error) {
      console.error("Error:", error);
      throw error;
    }
  });

  it("Sends a tip to the tipjar", async () => {
    const tipAmount = 0.5 * LAMPORTS_PER_SOL; // 0.5 SOL

    // Get initial balance
    const initialBalance = await provider.connection.getBalance(tipjarPda);
    console.log("\nInitial tipjar balance:", initialBalance / LAMPORTS_PER_SOL, "SOL");

    const tx = await program.methods
      .sendTip(new anchor.BN(tipAmount))
      .accounts({
        tipjar: tipjarPda,
        tipper: provider.wallet.publicKey,
        systemProgram: SystemProgram.programId,
      })
      .rpc();

    console.log("✅ Tip sent successfully!");
    console.log("Transaction signature:", tx);

    // Fetch and display the updated tipjar account
    const tipjarAccount = await program.account.tipjar.fetch(tipjarPda);
    const newBalance = await provider.connection.getBalance(tipjarPda);

    console.log("\nUpdated Tipjar Account:");
    console.log("  Total Tips:", tipjarAccount.totalTips.toString(), "lamports", `(${tipjarAccount.totalTips / LAMPORTS_PER_SOL} SOL)`);
    console.log("  Tip Count:", tipjarAccount.tipCount.toString());
    console.log("  Account Balance:", newBalance / LAMPORTS_PER_SOL, "SOL");
  });

  it("Sends multiple tips to the tipjar", async () => {
    const tip1 = 0.1 * LAMPORTS_PER_SOL;
    const tip2 = 0.2 * LAMPORTS_PER_SOL;

    // Send first tip
    await program.methods
      .sendTip(new anchor.BN(tip1))
      .accounts({
        tipjar: tipjarPda,
        tipper: provider.wallet.publicKey,
        systemProgram: SystemProgram.programId,
      })
      .rpc();

    console.log("✅ First tip sent: 0.1 SOL");

    // Send second tip
    await program.methods
      .sendTip(new anchor.BN(tip2))
      .accounts({
        tipjar: tipjarPda,
        tipper: provider.wallet.publicKey,
        systemProgram: SystemProgram.programId,
      })
      .rpc();

    console.log("✅ Second tip sent: 0.2 SOL");

    // Fetch and display the updated tipjar account
    const tipjarAccount = await program.account.tipjar.fetch(tipjarPda);
    const balance = await provider.connection.getBalance(tipjarPda);

    console.log("\nUpdated Tipjar Account:");
    console.log("  Total Tips Tracked:", tipjarAccount.totalTips.toString(), "lamports", `(${tipjarAccount.totalTips / LAMPORTS_PER_SOL} SOL)`);
    console.log("  Tip Count:", tipjarAccount.tipCount.toString());
    console.log("  Account Balance:", balance / LAMPORTS_PER_SOL, "SOL");
  });

  it("Owner withdraws from the tipjar", async () => {
    // Get current balance
    const tipjarAccount = await program.account.tipjar.fetch(tipjarPda);
    const balance = await provider.connection.getBalance(tipjarPda);
    const ownerBalanceBefore = await provider.connection.getBalance(provider.wallet.publicKey);

    console.log("\nBefore Withdrawal:");
    console.log("  Tipjar Balance:", balance / LAMPORTS_PER_SOL, "SOL");
    console.log("  Owner Balance:", ownerBalanceBefore / LAMPORTS_PER_SOL, "SOL");

    // Calculate rent exemption to know how much we can withdraw
    const accountInfo = await provider.connection.getAccountInfo(tipjarPda);
    const rent = await provider.connection.getMinimumBalanceForRentExemption(accountInfo.data.length);
    const availableBalance = balance - rent;

    // Withdraw 50% of available balance
    const withdrawAmount = Math.floor(availableBalance * 0.5);

    const tx = await program.methods
      .withdraw(new anchor.BN(withdrawAmount))
      .accounts({
        tipjar: tipjarPda,
        owner: provider.wallet.publicKey,
      })
      .rpc();

    console.log("\n✅ Withdrawal successful!");
    console.log("Transaction signature:", tx);
    console.log("Withdrawn amount:", withdrawAmount / LAMPORTS_PER_SOL, "SOL");

    // Fetch updated balances
    const newBalance = await provider.connection.getBalance(tipjarPda);
    const ownerBalanceAfter = await provider.connection.getBalance(provider.wallet.publicKey);

    console.log("\nAfter Withdrawal:");
    console.log("  Tipjar Balance:", newBalance / LAMPORTS_PER_SOL, "SOL");
    console.log("  Owner Balance:", ownerBalanceAfter / LAMPORTS_PER_SOL, "SOL");
    console.log("  Owner Gained:", (ownerBalanceAfter - ownerBalanceBefore) / LAMPORTS_PER_SOL, "SOL (minus transaction fees)");
  });

  it("Fails when non-owner tries to withdraw", async () => {
    // Create a new keypair to simulate a non-owner
    const nonOwner = anchor.web3.Keypair.generate();

    // Airdrop some SOL to the non-owner for transaction fees
    const airdropSig = await provider.connection.requestAirdrop(
      nonOwner.publicKey,
      1 * LAMPORTS_PER_SOL
    );
    await provider.connection.confirmTransaction(airdropSig);

    try {
      await program.methods
        .withdraw(new anchor.BN(1000))
        .accounts({
          tipjar: tipjarPda,
          owner: nonOwner.publicKey,
        })
        .signers([nonOwner])
        .rpc();

      // If we reach here, the test should fail
      throw new Error("Expected transaction to fail but it succeeded");
    } catch (error) {
      console.log("✅ Withdrawal correctly failed for non-owner");
      console.log("Error message:", error.message);
      // Check that it's the expected error (constraint violation)
      if (error.message.includes("has_one")) {
        console.log("✅ Correct error: Owner constraint violation");
      }
    }
  });

  it("Fails when trying to send 0 tip", async () => {
    try {
      await program.methods
        .sendTip(new anchor.BN(0))
        .accounts({
          tipjar: tipjarPda,
          tipper: provider.wallet.publicKey,
          systemProgram: SystemProgram.programId,
        })
        .rpc();

      throw new Error("Expected transaction to fail but it succeeded");
    } catch (error) {
      console.log("✅ Sending 0 tip correctly failed");
      console.log("Error:", error.error?.errorMessage || error.message);
      if (error.error?.errorMessage === "Amount must be greater than 0") {
        console.log("✅ Correct error message received");
      }
    }
  });
});
