// Solana Network Configuration
// Change this based on where your program is deployed

export const SOLANA_NETWORK =
    process.env.NEXT_PUBLIC_SOLANA_NETWORK || "http://127.0.0.1:8899";

// Available networks:
// - Local: http://127.0.0.1:8899
// - Devnet: https://api.devnet.solana.com
// - Mainnet: https://api.mainnet-beta.solana.com

export const IS_LOCAL = SOLANA_NETWORK.includes("127.0.0.1");
export const IS_DEVNET = SOLANA_NETWORK.includes("devnet");
export const IS_MAINNET = SOLANA_NETWORK.includes("mainnet");

