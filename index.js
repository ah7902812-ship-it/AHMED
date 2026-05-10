export default function Home() {
  return (
    <div style={{ minHeight: '100vh', background: '#0a0a0a', color: 'white', textAlign: 'center', padding: '50px' }}>
      <h1 style={{ fontSize: '50px', background: 'linear-gradient(135deg, #6366f1, #a855f7)', WebkitBackgroundClip: 'text', color: 'transparent' }}>
        Content Distribution Platform
      </h1>
      <p style={{ fontSize: '20px', marginTop: '20px' }}>For Omar Jehad & Mohamed Refaat</p>
      <button style={{ marginTop: '30px', padding: '15px 40px', background: '#6366f1', border: 'none', borderRadius: '10px', color: 'white', cursor: 'pointer' }}>
        Get Started
      </button>
    </div>
  );
}