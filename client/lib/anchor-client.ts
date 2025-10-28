import { AnchorProvider, Program, Idl } from "@coral-xyz/anchor";
import { Connection, PublicKey } from "@solana/web3.js";
import idl from "./tipjar.json";
import { SOLANA_NETWORK } from "./config";

export const PROGRAM_ID = new PublicKey("9SsavCqnPP6NLu6sbA8YsDDN23hQrXUKuPXZgp1C1ojQ");

// RPC endpoint - change this in config.ts based on your deployment
export const NETWORK = SOLANA_NETWORK;

export function getProgram(provider: AnchorProvider) {
    return new Program(idl as Idl, provider);
}

export function getTipjarPDA() {
    const [pda] = PublicKey.findProgramAddressSync(
        [Buffer.from("tipjar")],
        PROGRAM_ID
    );
    return pda;
}

export async function getTipjarAccount(program: any) {
    const tipjarPDA = getTipjarPDA();
    try {
        const account = await (program.account as any).tipjar.fetch(tipjarPDA);
        return account;
    } catch (error) {
        console.error("Error fetching tipjar account:", error);
        return null;
    }
}

