@echo off
chcp 65001 > nul
title Content Distribution Platform Setup
color 0A

echo ========================================
echo    Content Distribution Platform
echo    Created for Omar Jehad & Mohamed Refaat
echo ========================================
echo.

:: Create main project folder
mkdir content-platform-final 2>nul
cd content-platform-final

:: ========== CREATE BACKEND ==========
echo [1/4] Creating Backend...
mkdir server 2>nul
cd server

:: Create package.json
(
echo {
echo   "name": "backend",
echo   "version": "1.0.0",
echo   "scripts": {
echo     "start": "node server.js"
echo   },
echo   "dependencies": {
echo     "express": "^4.18.2",
echo     "cors": "^2.8.5",
echo     "bcryptjs": "^2.4.3",
echo     "jsonwebtoken": "^9.0.2",
echo     "mongoose": "^8.0.0",
echo     "dotenv": "^16.3.1"
echo   }
echo }
) > package.json

:: Create server.js
(
echo const express = require('express');
echo const cors = require('cors');
echo const jwt = require('jsonwebtoken');
echo const bcrypt = require('bcryptjs');
echo const mongoose = require('mongoose');
echo require('dotenv').config();
echo.
echo const app = express();
echo app.use(cors());
echo app.use(express.json());
echo.
echo // MongoDB Connection
echo mongoose.connect('mongodb://127.0.0.1:27017/content-platform')
echo   .then(() => console.log('✅ MongoDB Connected'))
echo   .catch(err => console.log('❌ MongoDB Error:', err.message));
echo.
echo // User Schema
echo const userSchema = new mongoose.Schema({
echo   name: { type: String, required: true },
echo   email: { type: String, required: true, unique: true },
echo   password: { type: String, required: true },
echo   role: { type: String, default: 'user' },
echo   createdAt: { type: Date, default: Date.now }
echo });
echo.
echo userSchema.pre('save', async function(next) {
echo   if (!this.isModified('password')) return next();
echo   this.password = await bcrypt.hash(this.password, 10);
echo   next();
echo });
echo.
echo const User = mongoose.model('User', userSchema);
echo.
echo // Order Schema for Pricing
echo const orderSchema = new mongoose.Schema({
echo   user: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
echo   videos: Number,
echo   platforms: Number,
echo   months: Number,
echo   totalAmount: Number,
echo   status: { type: String, default: 'pending' },
echo   createdAt: { type: Date, default: Date.now }
echo });
echo const Order = mongoose.model('Order', orderSchema);
echo.
echo // Auth Middleware
echo const auth = async (req, res, next) => {
echo   const token = req.headers.authorization?.split(' ')[1];
echo   if (!token) return res.status(401).json({ message: 'No token provided' });
echo   try {
echo     const decoded = jwt.verify(token, 'your_secret_key_2024');
echo     req.userId = decoded.userId;
echo     next();
echo   } catch {
echo     res.status(401).json({ message: 'Invalid token' });
echo   }
echo };
echo.
echo // ============ API ROUTES ============
echo.
echo // Register
echo app.post('/api/auth/register', async (req, res) => {
echo   try {
echo     const { name, email, password } = req.body;
echo     const existingUser = await User.findOne({ email });
echo     if (existingUser) return res.status(400).json({ message: 'User already exists' });
echo     const user = new User({ name, email, password });
echo     await user.save();
echo     const token = jwt.sign({ userId: user._id }, 'your_secret_key_2024', { expiresIn: '7d' });
echo     res.json({ token, user: { id: user._id, name, email, role: user.role } });
echo   } catch (error) {
echo     res.status(500).json({ message: error.message });
echo   }
echo });
echo.
echo // Login
echo app.post('/api/auth/login', async (req, res) => {
echo   try {
echo     const { email, password } = req.body;
echo     const user = await User.findOne({ email });
echo     if (!user) return res.status(401).json({ message: 'Invalid credentials' });
echo     const valid = await bcrypt.compare(password, user.password);
echo     if (!valid) return res.status(401).json({ message: 'Invalid credentials' });
echo     const token = jwt.sign({ userId: user._id }, 'your_secret_key_2024', { expiresIn: '7d' });
echo     res.json({ token, user: { id: user._id, name: user.name, email, role: user.role } });
echo   } catch (error) {
echo     res.status(500).json({ message: error.message });
echo   }
echo });
echo.
echo // Verify Token
echo app.get('/api/auth/verify', auth, async (req, res) => {
echo   try {
echo     const user = await User.findById(req.userId).select('-password');
echo     res.json({ user });
echo   } catch {
echo     res.status(500).json({ message: 'Server error' });
echo   }
echo });
echo.
echo // Calculate Price (Smart Pricing)
echo app.post('/api/payments/calculate-price', (req, res) => {
echo   const { videos, platforms, months } = req.body;
echo   let total = (videos * 20) + (platforms * 15) + (months * 50);
echo   if (total < 450) total = 450;
echo   res.json({ videos, platforms, months, total });
echo });
echo.
echo // Create Payment Intent
echo app.post('/api/payments/create-payment-intent', auth, async (req, res) => {
echo   try {
echo     const { videos, platforms, months } = req.body;
echo     let total = (videos * 20) + (platforms * 15) + (months * 50);
echo     if (total < 450) total = 450;
echo     const order = new Order({ user: req.userId, videos, platforms, months, totalAmount: total });
echo     await order.save();
echo     res.json({ clientSecret: 'mock_secret_' + Date.now(), orderId: order._id, amount: total });
echo   } catch (error) {
echo     res.status(500).json({ error: error.message });
echo   }
echo });
echo.
echo // Get User Orders
echo app.get('/api/orders', auth, async (req, res) => {
echo   try {
echo     const orders = await Order.find({ user: req.userId }).sort('-createdAt');
echo     res.json(orders);
echo   } catch (error) {
echo     res.status(500).json({ error: error.message });
echo   }
echo });
echo.
echo // Dashboard Analytics
echo app.get('/api/analytics/dashboard', auth, async (req, res) => {
echo   try {
echo     const orders = await Order.find({ user: req.userId, status: 'pending' });
echo     const totalSpent = orders.reduce((sum, o) => sum + o.totalAmount, 0);
echo     res.json({ totalOrders: orders.length, totalSpent, recentOrders: orders.slice(0, 5) });
echo   } catch (error) {
echo     res.status(500).json({ error: error.message });
echo   }
echo });
echo.
echo // Blog Posts (Sample)
echo const blogSchema = new mongoose.Schema({
echo   title: String,
echo   excerpt: String,
echo   content: String,
echo   image: String,
echo   date: { type: Date, default: Date.now }
echo });
echo const Blog = mongoose.model('Blog', blogSchema);
echo.
echo app.get('/api/blog', async (req, res) => {
echo   try {
echo     const blogs = await Blog.find().sort('-date');
echo     res.json(blogs);
echo   } catch (error) {
echo     res.status(500).json({ error: error.message });
echo   }
echo });
echo.
echo app.post('/api/blog', auth, async (req, res) => {
echo   try {
echo     const blog = new Blog(req.body);
echo     await blog.save();
echo     res.status(201).json(blog);
echo   } catch (error) {
echo     res.status(500).json({ error: error.message });
echo   }
echo });
echo.
echo // Sample blog posts
echo const initBlog = async () => {
echo   const count = await Blog.countDocuments();
echo   if (count === 0) {
echo     await Blog.create([
echo       { title: 'How to Grow Your YouTube Channel', excerpt: 'Tips and tricks for YouTube success...', content: 'Full article here...', image: 'youtube-tips' },
echo       { title: 'AI in Content Creation', excerpt: 'How AI is changing content creation...', content: 'Full article here...', image: 'ai-content' },
echo       { title: 'Multi-Platform Strategy', excerpt: 'Reach your audience everywhere...', content: 'Full article here...', image: 'multi-platform' }
echo     ]);
echo     console.log('📝 Sample blog posts created');
echo   }
echo };
echo initBlog();
echo.
echo // Root endpoint
echo app.get('/', (req, res) => {
echo   res.json({ message: 'Content Distribution Platform API', version: '1.0.0' });
echo });
echo.
echo // Start server
echo const PORT = process.env.PORT || 5000;
echo app.listen(PORT, () => {
echo   console.log(`🚀 Server running on http://localhost:${PORT}`);
echo });
) > server.js

cd ..

:: ========== CREATE FRONTEND ==========
echo [2/4] Creating Frontend...
mkdir client 2>nul
cd client

:: Create package.json
(
echo {
echo   "name": "client",
echo   "version": "1.0.0",
echo   "private": true,
echo   "scripts": {
echo     "dev": "next dev",
echo     "build": "next build",
echo     "start": "next start"
echo   },
echo   "dependencies": {
echo     "next": "14.0.0",
echo     "react": "18.2.0",
echo     "react-dom": "18.2.0",
echo     "axios": "^1.6.0"
echo   }
echo }
) > package.json

:: Create next.config.js
(
echo /** @type {import('next').NextConfig} */
echo const nextConfig = {
echo   reactStrictMode: true,
echo }
echo module.exports = nextConfig
) > next.config.js

:: Create pages directory
mkdir pages 2>nul
mkdir pages\api 2>nul

:: Create _app.js
(
echo import '../styles/globals.css'
echo.
echo function MyApp({ Component, pageProps }) {
echo   return ^<Component {...pageProps} /^>
echo }
echo.
echo export default MyApp
) > pages/_app.js

:: Create styles directory
mkdir styles 2>nul

:: Create globals.css
(
echo @import url('https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700;800&display=swap');
echo.
echo * {
echo   margin: 0;
echo   padding: 0;
echo   box-sizing: border-box;
echo }
echo.
echo body {
echo   font-family: 'Inter', sans-serif;
echo   background: linear-gradient(135deg, #0a0a0a 0%, #0f0f0f 100%);
echo   color: #ffffff;
echo   min-height: 100vh;
echo }
echo.
echo .glass {
echo   background: rgba(255, 255, 255, 0.05);
echo   backdrop-filter: blur(10px);
echo   border: 1px solid rgba(255, 255, 255, 0.1);
echo }
echo.
echo .gradient-text {
echo   background: linear-gradient(135deg, #6366f1, #a855f7, #06b6d4);
echo   -webkit-background-clip: text;
echo   -webkit-text-fill-color: transparent;
echo   background-clip: text;
echo }
) > styles/globals.css

:: Create index.js (Homepage)
(
echo import { useState, useEffect } from 'react';
echo import Head from 'next/head';
echo import Link from 'next/link';
echo.
echo export default function Home() {
echo   const [scrolled, setScrolled] = useState(false);
echo.
echo   useEffect(() => {
echo     window.addEventListener('scroll', () => setScrolled(window.scrollY > 50));
echo     return () => window.removeEventListener('scroll', () => setScrolled(window.scrollY > 50));
echo   }, []);
echo.
echo   const stats = [
echo     { value: '1M+', label: 'Content Distributed' },
echo     { value: '50K+', label: 'Happy Creators' },
echo     { value: '15+', label: 'Platforms Supported' },
echo     { value: '99.9%%', label: 'Uptime' }
echo   ];
echo.
echo   const services = [
echo     { title: 'Multi-Platform Distribution', desc: 'Publish to YouTube, TikTok, Instagram, Spotify, and more' },
echo     { title: 'AI-Powered Content', desc: 'Generate captions, SEO metadata, and follow-ups automatically' },
echo     { title: 'Advanced Analytics', desc: 'Track performance across all platforms in one dashboard' },
echo     { title: 'Smart Scheduling', desc: 'Post at optimal times for maximum engagement' },
echo     { title: 'Content Repurposing', desc: 'Transform long-form content into shorts automatically' },
echo     { title: 'Podcast Distribution', desc: 'Reach listeners on all major podcast platforms' }
echo   ];
echo.
echo   return (
echo     ^<^>
echo       ^<Head^>
echo         ^<title^>ContentFlow - AI-Powered Content Distribution Platform^</title^>
echo         ^<meta name="description" content="Distribute your content across all platforms. AI-powered captions, analytics, and scheduling for creators." /^>
echo       ^</Head^>
echo.
echo       {^/* Navbar */^}
echo       ^<nav style={{ position: 'fixed', top: 0, width: '100%', zIndex: 1000, transition: 'all 0.3s', background: scrolled ? 'rgba(15, 15, 15, 0.95)' : 'transparent', backdropFilter: scrolled ? 'blur(10px)' : 'none', borderBottom: scrolled ? '1px solid rgba(255,255,255,0.1)' : 'none' }}^>
echo         ^<div style={{ maxWidth: '1200px', margin: '0 auto', padding: '20px', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}^>
echo           ^<div style={{ fontSize: '28px', fontWeight: 'bold' }}^>
echo             ^<span className="gradient-text"^>ContentFlow^</span^>
echo           ^</div^>
echo           ^<div style={{ display: 'flex', gap: '30px', alignItems: 'center' }}^>
echo             ^<Link href="/" style={{ color: '#aaa', textDecoration: 'none' }}^>Home^</Link^>
echo             ^<Link href="/services" style={{ color: '#aaa', textDecoration: 'none' }}^>Services^</Link^>
echo             ^<Link href="/pricing" style={{ color: '#aaa', textDecoration: 'none' }}^>Pricing^</Link^>
echo             ^<Link href="/blog" style={{ color: '#aaa', textDecoration: 'none' }}^>Blog^</Link^>
echo             ^<Link href="/login"^>
echo               ^<button style={{ padding: '10px 25px', background: 'linear-gradient(135deg, #6366f1, #a855f7)', border: 'none', borderRadius: '50px', color: 'white', cursor: 'pointer', fontWeight: 'bold' }}^>Get Started^</button^>
echo             ^</Link^>
echo           ^</div^>
echo         ^</div^>
echo       ^</nav^>
echo.
echo       {^/* Hero Section */^}
echo       ^<section style={{ minHeight: '100vh', display: 'flex', alignItems: 'center', justifyContent: 'center', textAlign: 'center', padding: '100px 20px', position: 'relative', overflow: 'hidden' }}^>
echo         ^<div style={{ position: 'absolute', top: '20%', left: '10%', width: '300px', height: '300px', background: '#6366f1', borderRadius: '50%', filter: 'blur(100px)', opacity: 0.3 }}^>^</div^>
echo         ^<div style={{ position: 'absolute', bottom: '20%', right: '10%', width: '400px', height: '400px', background: '#a855f7', borderRadius: '50%', filter: 'blur(120px)', opacity: 0.3 }}^>^</div^>
echo         ^<div style={{ maxWidth: '800px', margin: '0 auto', zIndex: 1 }}^>
echo           ^<span style={{ display: 'inline-block', padding: '8px 20px', background: 'rgba(99,102,241,0.2)', borderRadius: '50px', fontSize: '14px', marginBottom: '20px' }}^>🚀 AI-Powered Platform^</span^>
echo           ^<h1 style={{ fontSize: '64px', fontWeight: 'bold', marginBottom: '20px' }}^>
echo             Distribute Your Content
echo             ^<span className="gradient-text" style={{ display: 'block' }}^>To Every Platform^</span^>
echo           ^</h1^>
echo           ^<p style={{ fontSize: '20px', color: '#aaa', marginBottom: '40px' }}^>
echo             Reach your audience everywhere. AI-powered distribution, analytics, and scheduling for creators.
echo           ^</p^>
echo           ^<div style={{ display: 'flex', gap: '20px', justifyContent: 'center' }}^>
echo             ^<Link href="/pricing"^>
echo               ^<button style={{ padding: '15px 40px', background: 'linear-gradient(135deg, #6366f1, #a855f7)', border: 'none', borderRadius: '50px', color: 'white', cursor: 'pointer', fontSize: '16px', fontWeight: 'bold' }}^>Start Free Trial^</button^>
echo             ^</Link^>
echo             ^<button style={{ padding: '15px 40px', background: 'transparent', border: '1px solid rgba(255,255,255,0.2)', borderRadius: '50px', color: 'white', cursor: 'pointer', fontSize: '16px' }}^>Watch Demo^</button^>
echo           ^</div^>
echo         ^</div^>
echo       ^</section^>
echo.
echo       {^/* Stats Section */^}
echo       ^<section style={{ padding: '80px 20px', maxWidth: '1200px', margin: '0 auto' }}^>
echo         ^<div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(200px, 1fr))', gap: '30px' }}^>
echo           {stats.map((stat, i) => (
echo             ^<div key={i} style={{ textAlign: 'center', padding: '30px', background: 'rgba(255,255,255,0.03)', borderRadius: '20px', border: '1px solid rgba(255,255,255,0.05)' }}^>
echo               ^<div style={{ fontSize: '48px', fontWeight: 'bold', background: 'linear-gradient(135deg, #6366f1, #a855f7)', WebkitBackgroundClip: 'text', WebkitTextFillColor: 'transparent', marginBottom: '10px' }}^>{stat.value}^</div^>
echo               ^<div style={{ color: '#aaa' }}^>{stat.label}^</div^>
echo             ^</div^>
echo           ))}
echo         ^</div^>
echo       ^</section^>
echo.
echo       {^/* Services Section */^}
echo       ^<section style={{ padding: '80px 20px', maxWidth: '1200px', margin: '0 auto' }}^>
echo         ^<h2 style={{ fontSize: '48px', textAlign: 'center', marginBottom: '20px' }}^>
echo           Everything You Need
echo           ^<span className="gradient-text"^> In One Platform^</span^>
echo         ^</h2^>
echo         ^<p style={{ textAlign: 'center', color: '#aaa', fontSize: '18px', marginBottom: '60px' }}^>
echo           Powerful tools to manage, distribute, and optimize your content
echo         ^</p^>
echo         ^<div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(350px, 1fr))', gap: '30px' }}^>
echo           {services.map((service, i) => (
echo             ^<div key={i} style={{ padding: '30px', background: 'rgba(255,255,255,0.03)', borderRadius: '20px', border: '1px solid rgba(255,255,255,0.05)', transition: 'transform 0.3s' }}^>
echo               ^<div style={{ width: '50px', height: '50px', background: 'linear-gradient(135deg, #6366f1, #a855f7)', borderRadius: '15px', marginBottom: '20px' }}^>^</div^>
echo               ^<h3 style={{ fontSize: '24px', marginBottom: '10px' }}^>{service.title}^</h3^>
echo               ^<p style={{ color: '#aaa' }}^>{service.desc}^</p^>
echo             ^</div^>
echo           ))}
echo         ^</div^>
echo       ^</section^>
echo.
echo       {^/* Omar Jehad & Mohamed Refaat Results */^}
echo       ^<section style={{ padding: '80px 20px', background: 'rgba(99,102,241,0.05)' }}^>
echo         ^<div style={{ maxWidth: '1200px', margin: '0 auto' }}^>
echo           ^<h2 style={{ fontSize: '48px', textAlign: 'center', marginBottom: '20px' }}^>
echo             Real Results From
echo             ^<span className="gradient-text"^> Our Clients^</span^>
echo           ^</h2^>
echo           ^<p style={{ textAlign: 'center', color: '#aaa', marginBottom: '60px' }}^>See how creators are growing with ContentFlow^</p^>
echo           ^<div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(300px, 1fr))', gap: '30px' }}^>
echo             ^<div style={{ background: 'rgba(255,255,255,0.03)', borderRadius: '20px', overflow: 'hidden', border: '1px solid rgba(255,255,255,0.05)' }}^>
echo               ^<div style={{ height: '200px', background: 'linear-gradient(135deg, #6366f1, #a855f7)', display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: '48px' }}^>🎬^</div^>
echo               ^<div style={{ padding: '25px' }}^>
echo                 ^<h3 style={{ fontSize: '22px' }}^>Omar Jehad^</h3^>
echo                 ^<p style={{ color: '#6366f1', marginBottom: '15px' }}^>YouTube Creator^</p^>
echo                 ^<div style={{ display: 'flex', justifyContent: 'space-between' }}^>
echo                   ^<div^>^<div style={{ fontSize: '24px', fontWeight: 'bold' }}^>+467%%^</div^>^<div style={{ color: '#aaa', fontSize: '12px' }}^>Engagement^</div^>^</div^>
echo                   ^<div^>^<div style={{ fontSize: '24px', fontWeight: 'bold' }}^>2.3M^</div^>^<div style={{ color: '#aaa', fontSize: '12px' }}^>Views^</div^>^</div^>
echo                 ^</div^>
echo               ^</div^>
echo             ^</div^>
echo             ^<div style={{ background: 'rgba(255,255,255,0.03)', borderRadius: '20px', overflow: 'hidden', border: '1px solid rgba(255,255,255,0.05)' }}^>
echo               ^<div style={{ height: '200px', background: 'linear-gradient(135deg, #a855f7, #06b6d4)', display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: '48px' }}^>🎙️^</div^>
echo               ^<div style={{ padding: '25px' }}^>
echo                 ^<h3 style={{ fontSize: '22px' }}^>Mohamed Refaat^</h3^>
echo                 ^<p style={{ color: '#6366f1', marginBottom: '15px' }}^>Content Creator^</p^>
echo                 ^<div style={{ display: 'flex', justifyContent: 'space-between' }}^>
echo                   ^<div^>^<div style={{ fontSize: '24px', fontWeight: 'bold' }}^>+892%%^</div^>^<div style={{ color: '#aaa', fontSize: '12px' }}^>Growth^</div^>^</div^>
echo                   ^<div^>^<div style={{ fontSize: '24px', fontWeight: 'bold' }}^>156K^</div^>^<div style={{ color: '#aaa', fontSize: '12px' }}^>Followers^</div^>^</div^>
echo                 ^</div^>
echo               ^</div^>
echo             ^</div^>
echo             ^<div style={{ background: 'rgba(255,255,255,0.03)', borderRadius: '20px', overflow: 'hidden', border: '1px solid rgba(255,255,255,0.05)' }}^>
echo               ^<div style={{ height: '200px', background: 'linear-gradient(135deg, #06b6d4, #6366f1)', display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: '48px' }}^>📊^</div^>
echo               ^<div style={{ padding: '25px' }}^>
echo                 ^<h3 style={{ fontSize: '22px' }}^>Podcast Network^</h3^>
echo                 ^<p style={{ color: '#6366f1', marginBottom: '15px' }}^>Audio Content^</p^>
echo                 ^<div style={{ display: 'flex', justifyContent: 'space-between' }}^>
echo                   ^<div^>^<div style={{ fontSize: '24px', fontWeight: 'bold' }}^>510K^</div^>^<div style={{ color: '#aaa', fontSize: '12px' }}^>Downloads^</div^>^</div^>
echo                   ^<div^>^<div style={{ fontSize: '24px', fontWeight: 'bold' }}^>45^</div^>^<div style={{ color: '#aaa', fontSize: '12px' }}^>Countries^</div^>^</div^>
echo                 ^</div^>
echo               ^</div^>
echo             ^</div^>
echo           ^</div^>
echo         ^</div^>
echo       ^</section^>
echo.
echo       {^/* Footer */^}
echo       ^<footer style={{ padding: '60px 20px 30px', borderTop: '1px solid rgba(255,255,255,0.05)' }}^>
echo         ^<div style={{ maxWidth: '1200px', margin: '0 auto', display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(200px, 1fr))', gap: '40px' }}^>
echo           ^<div^>
echo             ^<div style={{ fontSize: '24px', fontWeight: 'bold', marginBottom: '15px' }}^>^<span className="gradient-text"^>ContentFlow^</span^>^</div^>
echo             ^<p style={{ color: '#aaa' }}^>AI-powered content distribution for creators, podcasters, and brands.^</p^>
echo           ^</div^>
echo           ^<div^>
echo             ^<h4 style={{ marginBottom: '15px' }}^>Quick Links^</h4^>
echo             ^<ul style={{ listStyle: 'none', color: '#aaa' }}^>
echo               ^<li style={{ marginBottom: '8px' }}^>^<Link href="/" style={{ color: '#aaa', textDecoration: 'none' }}^>Home^</Link^>^</li^>
echo               ^<li style={{ marginBottom: '8px' }}^>^<Link href="/pricing" style={{ color: '#aaa', textDecoration: 'none' }}^>Pricing^</Link^>^</li^>
echo               ^<li style={{ marginBottom: '8px' }}^>^<Link href="/blog" style={{ color: '#aaa', textDecoration: 'none' }}^>Blog^</Link^>^</li^>
echo             ^</ul^>
echo           ^</div^>
echo           ^<div^>
echo             ^<h4 style={{ marginBottom: '15px' }}^>Contact^</h4^>
echo             ^<ul style={{ listStyle: 'none', color: '#aaa' }}^>
echo               ^<li style={{ marginBottom: '8px' }}^>📱 ^<a href="https://wa.me/201000000000" style={{ color: '#aaa', textDecoration: 'none' }}^>WhatsApp^</a^>^</li^>
echo               ^<li style={{ marginBottom: '8px' }}^>✉️ ^<a href="mailto:support@contentflow.com" style={{ color: '#aaa', textDecoration: 'none' }}^>Email^</a^>^</li^>
echo               ^<li style={{ marginBottom: '8px' }}^>📷 ^<a href="https://instagram.com" style={{ color: '#aaa', textDecoration: 'none' }}^>Instagram^</a^>^</li^>
echo             ^</ul^>
echo           ^</div^>
echo           ^<div^>
echo             ^<h4 style={{ marginBottom: '15px' }}^>Legal^</h4^>
echo             ^<ul style={{ listStyle: 'none', color: '#aaa' }}^>
echo               ^<li style={{ marginBottom: '8px' }}^>Privacy Policy^</li^>
echo               ^<li style={{ marginBottom: '8px' }}^>Terms of Service^</li^>
echo             ^</ul^>
echo           ^</div^>
echo         ^</div^>
echo         ^<div style={{ textAlign: 'center', marginTop: '50px', paddingTop: '30px', borderTop: '1px solid rgba(255,255,255,0.05)', color: '#555' }}^>
echo           ^<p^>© 2024 ContentFlow. All rights reserved. For Omar Jehad & Mohamed Refaat^</p^>
echo         ^</div^>
echo       ^</footer^>
echo     ^</^>
echo   );
echo }
) > pages/index.js

:: Create login page
mkdir pages\login 2>nul
(
echo import { useState } from 'react';
echo import { useRouter } from 'next/router';
echo import Link from 'next/link';
echo import Head from 'next/head';
echo.
echo export default function Login() {
echo   const [email, setEmail] = useState('');
echo   const [password, setPassword] = useState('');
echo   const [loading, setLoading] = useState(false);
echo   const router = useRouter();
echo.
echo   const handleSubmit = async (e) => {
echo     e.preventDefault();
echo     setLoading(true);
echo     try {
echo       const res = await fetch('http://localhost:5000/api/auth/login', {
echo         method: 'POST',
echo         headers: { 'Content-Type': 'application/json' },
echo         body: JSON.stringify({ email, password })
echo       });
echo       const data = await res.json();
echo       if (res.ok) {
echo         localStorage.setItem('token', data.token);
echo         localStorage.setItem('user', JSON.stringify(data.user));
echo         alert('Login successful!');
echo         router.push('/dashboard');
echo       } else {
echo         alert(data.message || 'Login failed');
echo       }
echo     } catch (error) {
echo       alert('Connection error. Make sure backend is running on port 5000');
echo     } finally {
echo       setLoading(false);
echo     }
echo   };
echo.
echo   return (
echo     ^<^>
echo       ^<Head^>^<title^>Login - ContentFlow^</title^>^</Head^>
echo       ^<div style={{ minHeight: '100vh', display: 'flex', alignItems: 'center', justifyContent: 'center', padding: '20px' }}^>
echo         ^<div style={{ position: 'absolute', top: 0, left: 0, right: 0, padding: '20px' }}^>
echo           ^<Link href="/" style={{ fontSize: '24px', fontWeight: 'bold', textDecoration: 'none' }}^>^<span className="gradient-text"^>ContentFlow^</span^>^</Link^>
echo         ^</div^>
echo         ^<div style={{ background: 'rgba(255,255,255,0.03)', padding: '40px', borderRadius: '20px', width: '100%', maxWidth: '400px', border: '1px solid rgba(255,255,255,0.05)' }}^>
echo           ^<h2 style={{ fontSize: '32px', marginBottom: '10px', textAlign: 'center' }}^>Welcome Back^</h2^>
echo           ^<p style={{ color: '#aaa', textAlign: 'center', marginBottom: '30px' }}^>Sign in to your account^</p^>
echo           ^<form onSubmit={handleSubmit}^>
echo             ^<input type="email" placeholder="Email Address" value={email} onChange={(e) => setEmail(e.target.value)} style={{ width: '100%', padding: '15px', marginBottom: '15px', background: 'rgba(255,255,255,0.05)', border: '1px solid rgba(255,255,255,0.1)', borderRadius: '10px', color: 'white' }} required /^>
echo             ^<input type="password" placeholder="Password" value={password} onChange={(e) => setPassword(e.target.value)} style={{ width: '100%', padding: '15px', marginBottom: '20px', background: 'rgba(255,255,255,0.05)', border: '1px solid rgba(255,255,255,0.1)', borderRadius: '10px', color: 'white' }} required /^>
echo             ^<button type="submit" disabled={loading} style={{ width: '100%', padding: '15px', background: 'linear-gradient(135deg, #6366f1, #a855f7)', border: 'none', borderRadius: '10px', color: 'white', fontSize: '16px', fontWeight: 'bold', cursor: 'pointer', opacity: loading ? 0.7 : 1 }}^>{loading ? 'Loading...' : 'Sign In'}^</button^>
echo           ^</form^>
echo           ^<p style={{ textAlign: 'center', marginTop: '20px', color: '#aaa' }}^>
echo             Don't have an account? ^<Link href="/register" style={{ color: '#6366f1', textDecoration: 'none' }}^>Sign up^</Link^>
echo           ^</p^>
echo         ^</div^>
echo       ^</div^>
echo     ^</^>
echo   );
echo }
) > pages\login\index.js

:: Create register page
mkdir pages\register 2>nul
(
echo import { useState } from 'react';
echo import { useRouter } from 'next/router';
echo import Link from 'next/link';
echo import Head from 'next/head';
echo.
echo export default function Register() {
echo   const [name, setName] = useState('');
echo   const [email, setEmail] = useState('');
echo   const [password, setPassword] = useState('');
echo   const [loading, setLoading] = useState(false);
echo   const router = useRouter();
echo.
echo   const handleSubmit = async (e) => {
echo     e.preventDefault();
echo     setLoading(true);
echo     try {
echo       const res = await fetch('http://localhost:5000/api/auth/register', {
echo         method: 'POST',
echo         headers: { 'Content-Type': 'application/json' },
echo         body: JSON.stringify({ name, email, password })
echo       });
echo       const data = await res.json();
echo       if (res.ok) {
echo         localStorage.setItem('token', data.token);
echo         localStorage.setItem('user', JSON.stringify(data.user));
echo         alert('Registration successful!');
echo         router.push('/dashboard');
echo       } else {
echo         alert(data.message || 'Registration failed');
echo       }
echo     } catch (error) {
echo       alert('Connection error. Make sure backend is running on port 5000');
echo     } finally {
echo       setLoading(false);
echo     }
echo   };
echo.
echo   return (
echo     ^<^>
echo       ^<Head^>^<title^>Register - ContentFlow^</title^>^</Head^>
echo       ^<div style={{ minHeight: '100vh', display: 'flex', alignItems: 'center', justifyContent: 'center', padding: '20px' }}^>
echo         ^<div style={{ position: 'absolute', top: 0, left: 0, right: 0, padding: '20px' }}^>
echo           ^<Link href="/" style={{ fontSize: '24px', fontWeight: 'bold', textDecoration: 'none' }}^>^<span className="gradient-text"^>ContentFlow^</span^>^</Link^>
echo         ^</div^>
echo         ^<div style={{ background: 'rgba(255,255,255,0.03)', padding: '40px', borderRadius: '20px', width: '100%', maxWidth: '400px', border: '1px solid rgba(255,255,255,0.05)' }}^>
echo           ^<h2 style={{ fontSize: '32px', marginBottom: '10px', textAlign: 'center' }}^>Create Account^</h2^>
echo           ^<p style={{ color: '#aaa', textAlign: 'center', marginBottom: '30px' }}^>Start distributing your content^</p^>
echo           ^<form onSubmit={handleSubmit}^>
echo             ^<input type="text" placeholder="Full Name" value={name} onChange={(e) => setName(e.target.value)} style={{ width: '100%', padding: '15px', marginBottom: '15px', background: 'rgba(255,255,255,0.05)', border: '1px solid rgba(255,255,255,0.1)', borderRadius: '10px', color: 'white' }} required /^>
echo             ^<input type="email" placeholder="Email Address" value={email} onChange={(e) => setEmail(e.target.value)} style={{ width: '100%', padding: '15px', marginBottom: '15px', background: 'rgba(255,255,255,0.05)', border: '1px solid rgba(255,255,255,0.1)', borderRadius: '10px', color: 'white' }} required /^>
echo             ^<input type="password" placeholder="Password" value={password} onChange={(e) => setPassword(e.target.value)} style={{ width: '100%', padding: '15px', marginBottom: '20px', background: 'rgba(255,255,255,0.05)', border: '1px solid rgba(255,255,255,0.1)', borderRadius: '10px', color: 'white' }} required /^>
echo             ^<button type="submit" disabled={loading} style={{ width: '100%', padding: '15px', background: 'linear-gradient(135deg, #6366f1, #a855f7)', border: 'none', borderRadius: '10px', color: 'white', fontSize: '16px', fontWeight: 'bold', cursor: 'pointer', opacity: loading ? 0.7 : 1 }}^>{loading ? 'Creating...' : 'Sign Up'}^</button^>
echo           ^</form^>
echo           ^<p style={{ textAlign: 'center', marginTop: '20px', color: '#aaa' }}^>
echo             Already have an account? ^<Link href="/login" style={{ color: '#6366f1', textDecoration: 'none' }}^>Sign in^</Link^>
echo           ^</p^>
echo         ^</div^>
echo       ^</div^>
echo     ^</^>
echo   );
echo }
) > pages\register\index.js

:: Create dashboard page
mkdir pages\dashboard 2>nul
(
echo import { useState, useEffect } from 'react';
echo import { useRouter } from 'next/router';
echo import Link from 'next/link';
echo import Head from 'next/head';
echo.
echo export default function Dashboard() {
echo   const [user, setUser] = useState(null);
echo   const [stats, setStats] = useState({ totalOrders: 0, totalSpent: 0 });
echo   const router = useRouter();
echo.
echo   useEffect(() => {
echo     const token = localStorage.getItem('token');
echo     const userData = localStorage.getItem('user');
echo     if (!token) {
echo       router.push('/login');
echo       return;
echo     }
echo     if (userData) setUser(JSON.parse(userData));
echo.
echo     // Fetch analytics
echo     fetch('http://localhost:5000/api/analytics/dashboard', {
echo       headers: { 'Authorization': `Bearer ${token}` }
echo     })
echo     .then(res => res.json())
echo     .then(data => setStats(data))
echo     .catch(console.error);
echo   }, []);
echo.
echo   const handleLogout = () => {
echo     localStorage.removeItem('token');
echo     localStorage.removeItem('user');
echo     router.push('/');
echo   };
echo.
echo   if (!user) return ^<div style={{ minHeight: '100vh', display: 'flex', alignItems: 'center', justifyContent: 'center' }}^>Loading...^</div^>;
echo.
echo   return (
echo     ^<^>
echo       ^<Head^>^<title^>Dashboard - ContentFlow^</title^>^</Head^>
echo       ^<div style={{ minHeight: '100vh' }}^>
echo         ^<nav style={{ background: 'rgba(15,15,15,0.95)', borderBottom: '1px solid rgba(255,255,255,0.05)', padding: '15px 20px' }}^>
echo           ^<div style={{ maxWidth: '1200px', margin: '0 auto', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}^>
echo             ^<Link href="/" style={{ fontSize: '24px', fontWeight: 'bold', textDecoration: 'none' }}^>^<span className="gradient-text"^>ContentFlow^</span^>^</Link^>
echo             ^<div style={{ display: 'flex', alignItems: 'center', gap: '20px' }}^>
echo               ^<span style={{ color: '#aaa' }}^>Welcome, {user.name}^</span^>
echo               ^<button onClick={handleLogout} style={{ padding: '8px 20px', background: 'transparent', border: '1px solid #ef4444', borderRadius: '8px', color: '#ef4444', cursor: 'pointer' }}^>Logout^</button^>
echo             ^</div^>
echo           ^</div^>
echo         ^</nav^>
echo         ^<div style={{ maxWidth: '1200px', margin: '0 auto', padding: '40px 20px' }}^>
echo           ^<h1 style={{ fontSize: '36px', marginBottom: '30px' }}^>Dashboard^</h1^>
echo           ^<div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(250px, 1fr))', gap: '20px', marginBottom: '40px' }}^>
echo             ^<div style={{ background: 'rgba(255,255,255,0.03)', padding: '25px', borderRadius: '15px', border: '1px solid rgba(255,255,255,0.05)' }}^>
echo               ^<div style={{ fontSize: '14px', color: '#aaa', marginBottom: '5px' }}^>Total Orders^</div^>
echo               ^<div style={{ fontSize: '36px', fontWeight: 'bold', background: 'linear-gradient(135deg, #6366f1, #a855f7)', WebkitBackgroundClip: 'text', WebkitTextFillColor: 'transparent' }}^>{stats.totalOrders}^</div^>
echo             ^</div^>
echo             ^<div style={{ background: 'rgba(255,255,255,0.03)', padding: '25px', borderRadius: '15px', border: '1px solid rgba(255,255,255,0.05)' }}^>
echo               ^<div style={{ fontSize: '14px', color: '#aaa', marginBottom: '5px' }}^>Total Spent^</div^>
echo               ^<div style={{ fontSize: '36px', fontWeight: 'bold', background: 'linear-gradient(135deg, #6366f1, #a855f7)', WebkitBackgroundClip: 'text', WebkitTextFillColor: 'transparent' }}^>${stats.totalSpent}^</div^>
echo             ^</div^>
echo           ^</div^>
echo           ^<div style={{ background: 'rgba(255,255,255,0.03)', padding: '30px', borderRadius: '15px', border: '1px solid rgba(255,255,255,0.05)' }}^>
echo             ^<h2 style={{ fontSize: '24px', marginBottom: '20px' }}^>Quick Actions^</h2^>
echo             ^<div style={{ display: 'flex', gap: '15px', flexWrap: 'wrap' }}^>
echo               ^<Link href="/pricing"^>
echo                 ^<button style={{ padding: '12px 25px', background: 'linear-gradient(135deg, #6366f1, #a855f7)', border: 'none', borderRadius: '10px', color: 'white', cursor: 'pointer' }}^>Buy Plan^</button^>
echo               ^</Link^>
echo               ^<button style={{ padding: '12px 25px', background: 'rgba(255,255,255,0.05)', border: '1px solid rgba(255,255,255,0.1)', borderRadius: '10px', color: 'white', cursor: 'pointer' }}^>Upload Content^</button^>
echo               ^<button style={{ padding: '12px 25px', background: 'rgba(255,255,255,0.05)', border: '1px solid rgba(255,255,255,0.1)', borderRadius: '10px', color: 'white', cursor: 'pointer' }}^>View Analytics^</button^>
echo             ^</div^>
echo           ^</div^>
echo         ^</div^>
echo       ^</div^>
echo     ^</^>
echo   );
echo }
) > pages\dashboard\index.js

:: Create pricing page
mkdir pages\pricing 2>nul
(
echo import { useState } from 'react';
echo import Link from 'next/link';
echo import Head from 'next/head';
echo.
echo export default function Pricing() {
echo   const [videos, setVideos] = useState(1);
echo   const [platforms, setPlatforms] = useState(1);
echo   const [months, setMonths] = useState(1);
echo   const [price, setPrice] = useState(450);
echo   const [loading, setLoading] = useState(false);
echo.
echo   const calculatePrice = () => {
echo     let total = (videos * 20) + (platforms * 15) + (months * 50);
echo     if (total < 450) total = 450;
echo     setPrice(total);
echo   };
echo.
echo   const updateVideos = (v) => { setVideos(v); setTimeout(calculatePrice, 0); };
echo   const updatePlatforms = (p) => { setPlatforms(p); setTimeout(calculatePrice, 0); };
echo   const updateMonths = (m) => { setMonths(m); setTimeout(calculatePrice, 0); };
echo.
echo   const handleCheckout = async () => {
echo     const token = localStorage.getItem('token');
echo     if (!token) {
echo       alert('Please login first');
echo       window.location.href = '/login';
echo       return;
echo     }
echo     setLoading(true);
echo     try {
echo       const res = await fetch('http://localhost:5000/api/payments/create-payment-intent', {
echo         method: 'POST',
echo         headers: { 'Content-Type': 'application/json', 'Authorization': `Bearer ${token}` },
echo         body: JSON.stringify({ videos, platforms, months })
echo       });
echo       const data = await res.json();
echo       if (res.ok) {
echo         alert(`Order created! Amount: $${price}\nDemo mode - In production this would process payment.`);
echo       } else {
echo         alert(data.error || 'Checkout failed');
echo       }
echo     } catch (error) {
echo       alert('Connection error. Make sure backend is running.');
echo     } finally {
echo       setLoading(false);
echo     }
echo   };
echo.
echo   return (
echo     ^<^>
echo       ^<Head^>^<title^>Pricing - ContentFlow^</title^>^</Head^>
echo       ^<div style={{ minHeight: '100vh' }}^>
echo         ^<nav style={{ background: 'rgba(15,15,15,0.95)', borderBottom: '1px solid rgba(255,255,255,0.05)', padding: '15px 20px' }}^>
echo           ^<div style={{ maxWidth: '1200px', margin: '0 auto', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}^>
echo             ^<Link href="/" style={{ fontSize: '24px', fontWeight: 'bold', textDecoration: 'none' }}^>^<span className="gradient-text"^>ContentFlow^</span^>^</Link^>
echo             ^<Link href="/login" style={{ padding: '10px 25px', background: 'linear-gradient(135deg, #6366f1, #a855f7)', border: 'none', borderRadius: '50px', color: 'white', textDecoration: 'none' }}^>Sign In^</Link^>
echo           ^</div^>
echo         ^</nav^>
echo         ^<div style={{ maxWidth: '1200px', margin: '0 auto', padding: '60px 20px' }}^>
echo           ^<h1 style={{ fontSize: '48px', textAlign: 'center', marginBottom: '20px' }}^>
echo             Smart Pricing
echo             ^<span className="gradient-text"^> Calculator^</span^>
echo           ^</h1^>
echo           ^<p style={{ textAlign: 'center', color: '#aaa', marginBottom: '50px' }}^>Pay only for what you need. Minimum $450^</p^>
echo           ^<div style={{ background: 'rgba(255,255,255,0.03)', padding: '40px', borderRadius: '20px', border: '1px solid rgba(255,255,255,0.05)', maxWidth: '800px', margin: '0 auto' }}^>
echo             ^<div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(200px, 1fr))', gap: '30px', marginBottom: '40px' }}^>
echo               ^<div^>
echo                 ^<label style={{ display: 'block', marginBottom: '10px', fontWeight: 'bold' }}^>Videos: {videos}^</label^>
echo                 ^<input type="range" min="1" max="50" value={videos} onChange={(e) => updateVideos(parseInt(e.target.value))} style={{ width: '100%' }} /^>
echo                 ^<p style={{ color: '#aaa', marginTop: '10px' }}^>${videos * 20}^</p^>
echo               ^</div^>
echo               ^<div^>
echo                 ^<label style={{ display: 'block', marginBottom: '10px', fontWeight: 'bold' }}^>Platforms: {platforms}^</label^>
echo                 ^<input type="range" min="1" max="15" value={platforms} onChange={(e) => updatePlatforms(parseInt(e.target.value))} style={{ width: '100%' }} /^>
echo                 ^<p style={{ color: '#aaa', marginTop: '10px' }}^>${platforms * 15}^</p^>
echo               ^</div^>
echo               ^<div^>
echo                 ^<label style={{ display: 'block', marginBottom: '10px', fontWeight: 'bold' }}^>Months: {months}^</label^>
echo                 ^<input type="range" min="1" max="12" value={months} onChange={(e) => updateMonths(parseInt(e.target.value))} style={{ width: '100%' }} /^>
echo                 ^<p style={{ color: '#aaa', marginTop: '10px' }}^>${months * 50}^</p^>
echo               ^</div^>
echo             ^</div^>
echo             ^<div style={{ textAlign: 'center', paddingTop: '30px', borderTop: '1px solid rgba(255,255,255,0.05)' }}^>
echo               ^<div style={{ fontSize: '48px', fontWeight: 'bold', marginBottom: '10px' }}^>
echo                 ^<span className="gradient-text"^>${price}^</span^>
echo               ^</div^>
echo               {price === 450 && ^<p style={{ color: '#06b6d4', marginBottom: '20px' }}^>✨ Minimum price applied^</p^>}
echo               ^<button onClick={handleCheckout} disabled={loading} style={{ padding: '15px 50px', background: 'linear-gradient(135deg, #6366f1, #a855f7)', border: 'none', borderRadius: '50px', color: 'white', fontSize: '18px', fontWeight: 'bold', cursor: 'pointer', opacity: loading ? 0.7 : 1 }}^>{loading ? 'Processing...' : 'Start Now'}^</button^>
echo             ^</div^>
echo           ^</div^>
echo         ^</div^>
echo       ^</div^>
echo     ^</^>
echo   );
echo }
) > pages\pricing\index.js

:: Create blog page
mkdir pages\blog 2>nul
(
echo import { useState, useEffect } from 'react';
echo import Link from 'next/link';
echo import Head from 'next/head';
echo.
echo export default function Blog() {
echo   const [blogs, setBlogs] = useState([]);
echo.
echo   useEffect(() => {
echo     fetch('http://localhost:5000/api/blog')
echo       .then(res => res.json())
echo       .then(data => setBlogs(data))
echo       .catch(console.error);
echo   }, []);
echo.
echo   return (
echo     ^<^>
echo       ^<Head^>^<title^>Blog - ContentFlow^</title^>^</Head^>
echo       ^<div style={{ minHeight: '100vh' }}^>
echo         ^<nav style={{ background: 'rgba(15,15,15,0.95)', borderBottom: '1px solid rgba(255,255,255,0.05)', padding: '15px 20px' }}^>
echo           ^<div style={{ maxWidth: '1200px', margin: '0 auto', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}^>
echo             ^<Link href="/" style={{ fontSize: '24px', fontWeight: 'bold', textDecoration: 'none' }}^>^<span className="gradient-text"^>ContentFlow^</span^>^</Link^>
echo           ^</div^>
echo         ^</nav^>
echo         ^<div style={{ maxWidth: '1200px', margin: '0 auto', padding: '60px 20px' }}^>
echo           ^<h1 style={{ fontSize: '48px', textAlign: 'center', marginBottom: '20px' }}^>^<span className="gradient-text"^>Blog^</span^>^</h1^>
echo           ^<p style={{ textAlign: 'center', color: '#aaa', marginBottom: '50px' }}^>Latest insights and tips for content creators^</p^>
echo           ^<div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(350px, 1fr))', gap: '30px' }}^>
echo             {blogs.map((blog, i) => (
echo               ^<div key={i} style={{ background: 'rgba(255,255,255,0.03)', borderRadius: '20px', overflow: 'hidden', border: '1px solid rgba(255,255,255,0.05)' }}^>
echo                 ^<div style={{ height: '200px', background: 'linear-gradient(135deg, #6366f1, #a855f7)', display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: '48px' }}^>📝^</div^>
echo                 ^<div style={{ padding: '25px' }}^>
echo                   ^<h3 style={{ fontSize: '22px', marginBottom: '10px' }}^>{blog.title}^</h3^>
echo                   ^<p style={{ color: '#aaa', marginBottom: '15px' }}^>{blog.excerpt}^</p^>
echo                   ^<Link href={`/blog/${blog._id}`} style={{ color: '#6366f1', textDecoration: 'none' }}^>Read More →^</Link^>
echo                 ^</div^>
echo               ^</div^>
echo             ))}
echo           ^</div^>
echo         ^</div^>
echo       ^</div^>
echo     ^</^>
echo   );
echo }
) > pages\blog\index.js

:: Create services page
mkdir pages\services 2>nul
(
echo import Link from 'next/link';
echo import Head from 'next/head';
echo.
echo export default function Services() {
echo   const services = [
echo     { title: 'Content Distribution', desc: 'Distribute your content to all major platforms automatically.' },
echo     { title: 'Podcast Distribution', desc: 'Reach listeners on Spotify, Apple Podcasts, and more.' },
echo     { title: 'Shorts Distribution', desc: 'Optimize and distribute short-form content.' },
echo     { title: 'SEO Optimization', desc: 'AI-powered SEO for maximum visibility.' },
echo     { title: 'Analytics Dashboard', desc: 'Track performance across all platforms.' },
echo     { title: 'Content Repurposing', desc: 'Transform long content into shorts.' },
echo     { title: 'Caption Writing', desc: 'AI-generated captions for every platform.' },
echo     { title: 'Smart Scheduling', desc: 'Post at optimal times for engagement.' }
echo   ];
echo.
echo   return (
echo     ^<^>
echo       ^<Head^>^<title^>Services - ContentFlow^</title^>^</Head^>
echo       ^<nav style={{ background: 'rgba(15,15,15,0.95)', borderBottom: '1px solid rgba(255,255,255,0.05)', padding: '15px 20px' }}^>
echo         ^<div style={{ maxWidth: '1200px', margin: '0 auto', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}^>
echo           ^<Link href="/" style={{ fontSize: '24px', fontWeight: 'bold', textDecoration: 'none' }}^>^<span className="gradient-text"^>ContentFlow^</span^>^</Link^>
echo         ^</div^>
echo       ^</nav^>
echo       ^<div style={{ maxWidth: '1200px', margin: '0 auto', padding: '60px 20px' }}^>
echo         ^<h1 style={{ fontSize: '48px', textAlign: 'center', marginBottom: '20px' }}^>Our ^<span className="gradient-text"^>Services^</span^>^</h1^>
echo         ^<p style={{ textAlign: 'center', color: '#aaa', marginBottom: '50px' }}^>Everything you need to succeed as a content creator^</p^>
echo         ^<div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(350px, 1fr))', gap: '30px' }}^>
echo           {services.map((service, i) => (
echo             ^<div key={i} style={{ background: 'rgba(255,255,255,0.03)', padding: '30px', borderRadius: '20px', border: '1px solid rgba(255,255,255,0.05)' }}^>
echo               ^<div style={{ width: '50px', height: '50px', background: 'linear-gradient(135deg, #6366f1, #a855f7)', borderRadius: '15px', marginBottom: '20px' }}^>^</div^>
echo               ^<h3 style={{ fontSize: '22px', marginBottom: '10px' }}^>{service.title}^</h3^>
echo               ^<p style={{ color: '#aaa' }}^>{service.desc}^</p^>
echo             ^</div^>
echo           ))}
echo         ^</div^>
echo       ^</div^>
echo     ^</^>
echo   );
echo }
) > pages\services\index.js

cd ../..

echo.
echo ========================================
echo ✅ SETUP COMPLETE!
echo ========================================
echo.
echo Now open TWO terminals:
echo.
echo [TERMINAL 1 - Backend]
echo   cd %cd%\content-platform-final\server
echo   npm install
echo   node server.js
echo.
echo [TERMINAL 2 - Frontend]  
echo   cd %cd%\content-platform-final\client
echo   npm install
echo   npm run dev
echo.
echo Then open: http://localhost:3000
echo.
echo ========================================
pause