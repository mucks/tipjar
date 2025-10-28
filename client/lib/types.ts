import { PublicKey } from "@solana/web3.js";
import { BN } from "@coral-xyz/anchor";

export interface TipjarAccount {
    owner: PublicKey;
    totalTips: BN;
    tipCount: BN;
}

export type TipjarProgram = any; // We'll use any for now to avoid complex IDL typing

