"use client";

import { useConnection, useWallet } from "@solana/wallet-adapter-react";
import { WalletMultiButton } from "@solana/wallet-adapter-react-ui";
import { AnchorProvider } from "@coral-xyz/anchor";
import { LAMPORTS_PER_SOL, PublicKey, SystemProgram } from "@solana/web3.js";
import { useEffect, useState } from "react";
import { QRCodeSVG } from "qrcode.react";
import * as anchor from "@coral-xyz/anchor";
import {
    getProgram,
    getTipjarPDA,
    getTipjarAccount,
    PROGRAM_ID,
} from "../lib/anchor-client";

export default function TipJar() {
    const { connection } = useConnection();
    const wallet = useWallet();
    const [tipjarData, setTipjarData] = useState<any>(null);
    const [balance, setBalance] = useState<number>(0);
    const [isOwner, setIsOwner] = useState(false);
    const [loading, setLoading] = useState(false);
    const [withdrawAmount, setWithdrawAmount] = useState("");
    const [tipAmount, setTipAmount] = useState("0.1");
    const [tipping, setTipping] = useState(false);

    const tipjarPDA = getTipjarPDA();

    useEffect(() => {
        loadTipjarData();
        // Load data on mount and whenever connection/wallet changes
    }, [wallet.publicKey, connection]);

    const getProvider = () => {
        if (!wallet.publicKey) return null;
        const provider = new AnchorProvider(
            connection,
            wallet as any,
            AnchorProvider.defaultOptions()
        );
        return provider;
    };

    const loadTipjarData = async () => {
        try {
            // Load data even without wallet connection
            const dummyProvider = new AnchorProvider(
                connection,
                {} as any,
                AnchorProvider.defaultOptions()
            );
            const program = getProgram(dummyProvider);
            const data = await getTipjarAccount(program);

            if (data) {
                setTipjarData(data);
                const bal = await connection.getBalance(tipjarPDA);
                setBalance(bal);

                // Check if connected wallet is the owner
                if (wallet.publicKey) {
                    setIsOwner(data.owner.equals(wallet.publicKey));
                }
            }
        } catch (error) {
            console.error("Error loading tipjar data:", error);
        }
    };

    const handleSendTip = async () => {
        if (!wallet.publicKey) {
            alert("Please connect your wallet first!");
            return;
        }

        try {
            setTipping(true);
            const provider = getProvider();
            if (!provider) return;

            const program = getProgram(provider);
            const amount = parseFloat(tipAmount) * LAMPORTS_PER_SOL;

            if (isNaN(amount) || amount <= 0) {
                alert("Please enter a valid amount");
                return;
            }

            const tx = await program.methods
                .sendTip(new anchor.BN(amount))
                .accounts({
                    tipjar: tipjarPDA,
                    tipper: wallet.publicKey,
                    systemProgram: SystemProgram.programId,
                })
                .rpc();

            console.log("Tip sent successfully:", tx);
            alert(`Successfully sent ${tipAmount} SOL tip! 🎉`);
            setTipAmount("0.1");
            await loadTipjarData();
        } catch (error: any) {
            console.error("Error sending tip:", error);
            alert(`Error: ${error.message}`);
        } finally {
            setTipping(false);
        }
    };

    const handleWithdraw = async () => {
        if (!wallet.publicKey || !isOwner) return;

        try {
            setLoading(true);
            const provider = getProvider();
            if (!provider) return;

            const program = getProgram(provider);
            const amount = parseFloat(withdrawAmount) * LAMPORTS_PER_SOL;

            if (isNaN(amount) || amount <= 0) {
                alert("Please enter a valid amount");
                return;
            }

            const tx = await program.methods
                .withdraw(new anchor.BN(amount))
                .accounts({
                    tipjar: tipjarPDA,
                    owner: wallet.publicKey,
                })
                .rpc();

            console.log("Withdrawal successful:", tx);
            alert(`Successfully withdrew ${withdrawAmount} SOL!`);
            setWithdrawAmount("");
            await loadTipjarData();
        } catch (error: any) {
            console.error("Error withdrawing:", error);
            alert(`Error: ${error.message}`);
        } finally {
            setLoading(false);
        }
    };

    // Generate Solana Pay URL for QR code
    const generatePaymentUrl = () => {
        // For a simple transfer, we create a Solana Pay URL
        // In production, you might want to create a proper Solana Pay transaction request
        return `solana:${tipjarPDA.toBase58()}?amount=0.1&label=Tip%20Jar&message=Thank%20you%20for%20the%20tip!`;
    };

    const availableBalance =
        balance > 0 ? (balance - 896 * 1200) / LAMPORTS_PER_SOL : 0; // Rough rent estimate

    return (
        <div className="min-h-screen bg-gradient-to-br from-purple-500 via-pink-500 to-red-500 flex items-center justify-center p-4">
            <div className="max-w-2xl w-full">
                {/* Header */}
                <div className="text-center mb-8">
                    <h1 className="text-5xl font-bold text-white mb-2">🎯 Tip Jar</h1>
                    <p className="text-white text-lg opacity-90">
                        Send tips via Solana - Instant, low-cost, on-chain!
                    </p>
                </div>

                {/* Main Card */}
                <div className="bg-white rounded-3xl shadow-2xl p-8">
                    {/* Wallet Connection */}
                    <div className="flex justify-center mb-6">
                        <WalletMultiButton className="!bg-gradient-to-r !from-purple-600 !to-pink-600 hover:!from-purple-700 hover:!to-pink-700" />
                    </div>

                    {isOwner && wallet.connected ? (
                        // Owner View
                        <div className="space-y-6">
                            <div className="bg-gradient-to-r from-green-50 to-emerald-50 rounded-2xl p-6 border-2 border-green-200">
                                <div className="flex items-center justify-center mb-4">
                                    <span className="text-3xl mr-3">👑</span>
                                    <h2 className="text-2xl font-bold text-green-800">
                                        Owner Dashboard
                                    </h2>
                                </div>

                                {/* Balance Display */}
                                <div className="text-center mb-6">
                                    <p className="text-gray-600 mb-2">Total Tips Received</p>
                                    <p className="text-5xl font-bold text-green-600 mb-1">
                                        {tipjarData
                                            ? (tipjarData.totalTips / LAMPORTS_PER_SOL).toFixed(4)
                                            : "0"}{" "}
                                        SOL
                                    </p>
                                    <p className="text-sm text-gray-500">
                                        {tipjarData ? tipjarData.tipCount.toString() : "0"} tips
                                        received
                                    </p>
                                </div>

                                {/* Current Balance */}
                                <div className="bg-white rounded-xl p-4 mb-4">
                                    <p className="text-gray-600 text-sm mb-1">
                                        Available to Withdraw
                                    </p>
                                    <p className="text-3xl font-bold text-gray-800">
                                        {availableBalance.toFixed(4)} SOL
                                    </p>
                                    <p className="text-xs text-gray-500 mt-1">
                                        Account Balance: {(balance / LAMPORTS_PER_SOL).toFixed(4)}{" "}
                                        SOL
                                    </p>
                                </div>

                                {/* Withdraw Form */}
                                <div className="space-y-4">
                                    <div>
                                        <label className="block text-sm font-medium text-gray-700 mb-2">
                                            Withdrawal Amount (SOL)
                                        </label>
                                        <input
                                            type="number"
                                            step="0.01"
                                            value={withdrawAmount}
                                            onChange={(e) => setWithdrawAmount(e.target.value)}
                                            placeholder="0.00"
                                            className="w-full px-4 py-3 rounded-xl border-2 border-gray-300 focus:border-green-500 focus:ring-2 focus:ring-green-200 outline-none transition"
                                        />
                                    </div>

                                    <button
                                        onClick={handleWithdraw}
                                        disabled={loading || !withdrawAmount || parseFloat(withdrawAmount) <= 0}
                                        className="w-full bg-gradient-to-r from-green-600 to-emerald-600 text-white font-bold py-4 rounded-xl hover:from-green-700 hover:to-emerald-700 disabled:opacity-50 disabled:cursor-not-allowed transition transform hover:scale-105 active:scale-95"
                                    >
                                        {loading ? "Processing..." : "💰 Withdraw Funds"}
                                    </button>

                                    <button
                                        onClick={() => setWithdrawAmount(availableBalance.toFixed(4))}
                                        className="w-full text-green-600 font-medium py-2 hover:text-green-700 transition"
                                    >
                                        Withdraw All Available
                                    </button>
                                </div>
                            </div>

                            {/* Tipjar Info */}
                            <div className="bg-gray-50 rounded-xl p-4">
                                <p className="text-xs text-gray-600 mb-2">Tipjar Address:</p>
                                <p className="text-xs font-mono bg-white p-2 rounded break-all">
                                    {tipjarPDA.toBase58()}
                                </p>
                            </div>
                        </div>
                    ) : (
                        // Public/Tipper View - ALWAYS SHOWN
                        <div className="space-y-6">
                            {/* Primary: QR Code Section */}
                            <div className="text-center">
                                <h2 className="text-3xl font-bold text-gray-800 mb-2">
                                    💝 Scan to Tip
                                </h2>
                                <p className="text-gray-600 text-lg font-medium">
                                    ⭐ Easiest Way: Scan with Your Wallet
                                </p>
                            </div>

                            {/* QR Code - Extra Prominent */}
                            <div className="flex justify-center">
                                <div className="bg-gradient-to-br from-purple-100 to-pink-100 p-8 rounded-3xl shadow-2xl border-4 border-purple-300">
                                    <QRCodeSVG
                                        value={generatePaymentUrl()}
                                        size={280}
                                        level="H"
                                        includeMargin={true}
                                    />
                                    <p className="text-center text-purple-700 font-bold mt-4 text-sm">
                                        👆 Open your Solana wallet & scan
                                    </p>
                                </div>
                            </div>

                            {/* Stats */}
                            {tipjarData && (
                                <div className="grid grid-cols-2 gap-4">
                                    <div className="bg-gradient-to-br from-purple-50 to-pink-50 rounded-xl p-4 text-center border-2 border-purple-200">
                                        <p className="text-purple-600 text-sm font-medium mb-1">
                                            Total Tips
                                        </p>
                                        <p className="text-2xl font-bold text-purple-700">
                                            {(tipjarData.totalTips / LAMPORTS_PER_SOL).toFixed(4)} ◎
                                        </p>
                                    </div>
                                    <div className="bg-gradient-to-br from-pink-50 to-red-50 rounded-xl p-4 text-center border-2 border-pink-200">
                                        <p className="text-pink-600 text-sm font-medium mb-1">
                                            Tip Count
                                        </p>
                                        <p className="text-2xl font-bold text-pink-700">
                                            {tipjarData.tipCount.toString()}
                                        </p>
                                    </div>
                                </div>
                            )}

                            {/* Divider */}
                            <div className="flex items-center gap-4">
                                <div className="flex-1 border-t-2 border-gray-300"></div>
                                <span className="text-gray-500 font-medium">OR</span>
                                <div className="flex-1 border-t-2 border-gray-300"></div>
                            </div>

                            {/* Secondary: Wallet Tip Section */}
                            {wallet.connected ? (
                                <div className="bg-gradient-to-r from-blue-50 to-indigo-50 rounded-2xl p-6 border-2 border-blue-200">
                                    <h3 className="text-xl font-bold text-blue-900 mb-4 text-center">
                                        💳 Tip with Connected Wallet
                                    </h3>

                                    <div className="space-y-4">
                                        {/* Quick Tip Buttons */}
                                        <div className="grid grid-cols-3 gap-2">
                                            <button
                                                onClick={() => setTipAmount("0.05")}
                                                className="py-2 px-3 bg-white border-2 border-blue-300 text-blue-700 font-bold rounded-lg hover:bg-blue-50 transition"
                                            >
                                                0.05 ◎
                                            </button>
                                            <button
                                                onClick={() => setTipAmount("0.1")}
                                                className="py-2 px-3 bg-white border-2 border-blue-300 text-blue-700 font-bold rounded-lg hover:bg-blue-50 transition"
                                            >
                                                0.1 ◎
                                            </button>
                                            <button
                                                onClick={() => setTipAmount("0.5")}
                                                className="py-2 px-3 bg-white border-2 border-blue-300 text-blue-700 font-bold rounded-lg hover:bg-blue-50 transition"
                                            >
                                                0.5 ◎
                                            </button>
                                        </div>

                                        {/* Custom Amount */}
                                        <div>
                                            <label className="block text-sm font-medium text-gray-700 mb-2">
                                                Or Enter Custom Amount (SOL)
                                            </label>
                                            <input
                                                type="number"
                                                step="0.01"
                                                value={tipAmount}
                                                onChange={(e) => setTipAmount(e.target.value)}
                                                placeholder="0.00"
                                                className="w-full px-4 py-3 rounded-xl border-2 border-gray-300 focus:border-blue-500 focus:ring-2 focus:ring-blue-200 outline-none transition"
                                            />
                                        </div>

                                        {/* Send Tip Button */}
                                        <button
                                            onClick={handleSendTip}
                                            disabled={tipping || !tipAmount || parseFloat(tipAmount) <= 0}
                                            className="w-full bg-gradient-to-r from-blue-600 to-indigo-600 text-white font-bold py-4 rounded-xl hover:from-blue-700 hover:to-indigo-700 disabled:opacity-50 disabled:cursor-not-allowed transition transform hover:scale-105 active:scale-95 shadow-lg"
                                        >
                                            {tipping ? "Sending..." : `🚀 Send ${tipAmount} SOL Tip`}
                                        </button>
                                    </div>
                                </div>
                            ) : (
                                <div className="bg-blue-50 border-2 border-blue-200 rounded-xl p-4 text-center">
                                    <p className="text-blue-900 font-medium mb-2">
                                        💡 Want to tip directly from this page?
                                    </p>
                                    <p className="text-blue-700 text-sm">
                                        Connect your wallet above to send tips with one click!
                                    </p>
                                </div>
                            )}

                            {/* Tipjar Address */}
                            <div className="bg-gray-50 rounded-xl p-4">
                                <p className="text-sm text-gray-600 mb-2 text-center font-medium">
                                    Or Copy Address Manually:
                                </p>
                                <div className="flex items-center justify-between bg-white p-3 rounded-lg">
                                    <p className="text-xs font-mono text-gray-800 truncate flex-1">
                                        {tipjarPDA.toBase58()}
                                    </p>
                                    <button
                                        onClick={() => {
                                            navigator.clipboard.writeText(tipjarPDA.toBase58());
                                            alert("Address copied! 📋");
                                        }}
                                        className="ml-2 px-3 py-2 bg-purple-100 text-purple-700 rounded-lg hover:bg-purple-200 transition text-sm font-medium"
                                    >
                                        📋 Copy
                                    </button>
                                </div>
                            </div>
                        </div>
                    )}
                </div>

                {/* Footer */}
                <div className="text-center mt-6">
                    <p className="text-white text-sm opacity-75">
                        Powered by Solana & Anchor Framework
                    </p>
                </div>
            </div>
        </div>
    );
}

