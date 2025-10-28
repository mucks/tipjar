import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  /* config options here */
  output: 'standalone',

  // Enable faster refresh in development
  reactStrictMode: true,

  // Optimize images
  images: {
    unoptimized: true, // For static export compatibility
  },
};

export default nextConfig;
