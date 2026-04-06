import { useState, useEffect } from "react";
import { useNavigate, Link } from "react-router-dom";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Button } from "@/components/ui/button";
import { Bus, Lock, User, ArrowRight, Shield, Zap, BarChart3, CheckCircle2, Eye, EyeOff } from "lucide-react";
import { motion } from "framer-motion";
import { useAuth } from "@/contexts/AuthContext";
import ErrorAlert from "@/components/ErrorAlert";

const features = [
  {
    icon: Zap,
    title: "Real-time Tracking",
    desc: "Monitor fleet positions and trip statuses as they happen.",
  },
  {
    icon: Shield,
    title: "Secure & Reliable",
    desc: "Enterprise-grade security with 99.9% uptime guarantee.",
  },
  {
    icon: BarChart3,
    title: "Smart Analytics",
    desc: "Actionable insights to optimize routes and revenue.",
  },
];

const Login = () => {
  const navigate = useNavigate();
  const { login, isAuthenticated, isLoading, error, clearError } = useAuth();
  const [username, setUsername] = useState("");
  const [password, setPassword] = useState("");
  const [showPassword, setShowPassword] = useState(false);

  useEffect(() => {
    if (isAuthenticated) {
      navigate("/");
    }
  }, [isAuthenticated, navigate]);

  const handleLogin = async (e: React.FormEvent) => {
    e.preventDefault();
    clearError();
    if (!username.trim() || !password.trim()) return;
    await login({ username: username.trim(), password });
  };

  return (
    <div className="min-h-screen flex flex-col lg:flex-row">
      {/* Left — branding panel */}
      <div className="hidden lg:flex lg:w-[52%] relative flex-col justify-between p-10 xl:p-14 overflow-hidden bg-[hsl(var(--sidebar-bg))]">
        {/* Background effects */}
        <div className="absolute inset-0">
          <div className="absolute inset-0 opacity-[0.03]" style={{
            backgroundImage: `linear-gradient(hsl(var(--accent)) 1px, transparent 1px), linear-gradient(90deg, hsl(var(--accent)) 1px, transparent 1px)`,
            backgroundSize: '60px 60px',
          }} />
          <motion.div
            animate={{ scale: [1, 1.15, 1], opacity: [0.08, 0.15, 0.08] }}
            transition={{ duration: 8, repeat: Infinity, ease: "easeInOut" }}
            className="absolute -top-40 -right-40 w-[600px] h-[600px] rounded-full"
            style={{ background: 'radial-gradient(circle, hsl(var(--accent)), transparent 65%)' }}
          />
          <motion.div
            animate={{ scale: [1, 1.1, 1], opacity: [0.06, 0.12, 0.06] }}
            transition={{ duration: 10, repeat: Infinity, ease: "easeInOut", delay: 2 }}
            className="absolute -bottom-60 -left-40 w-[500px] h-[500px] rounded-full"
            style={{ background: 'radial-gradient(circle, hsl(var(--primary)), transparent 65%)' }}
          />
        </div>

        {/* Logo */}
        <motion.div
          initial={{ opacity: 0, y: -10 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.5 }}
          className="relative z-10 flex items-center gap-3"
        >
          <div className="h-11 w-11 rounded-xl bg-gradient-to-br from-[hsl(var(--primary))] to-[hsl(var(--accent))] flex items-center justify-center shadow-lg">
            <Bus className="h-5 w-5 text-primary-foreground" />
          </div>
          <span className="text-lg font-bold text-[hsl(var(--sidebar-primary-foreground))]" style={{ fontFamily: 'var(--font-display)' }}>
            CountryBoy
          </span>
        </motion.div>

        {/* Hero + features */}
        <motion.div
          initial={{ opacity: 0, y: 30 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.7, delay: 0.15 }}
          className="relative z-10 space-y-10"
        >
          <div className="space-y-4">
            <div className="inline-flex items-center gap-2 px-3 py-1.5 rounded-full bg-[hsl(var(--accent)/0.15)] border border-[hsl(var(--accent)/0.25)]">
              <span className="h-1.5 w-1.5 rounded-full bg-[hsl(var(--success))] animate-pulse" />
              <span className="text-xs font-medium text-[hsl(var(--accent))]">System Online</span>
            </div>
            <h2 className="text-4xl xl:text-5xl font-bold text-[hsl(var(--sidebar-primary-foreground))] leading-[1.15] tracking-tight" style={{ fontFamily: 'var(--font-display)' }}>
              Fleet operations,{" "}
              <span className="bg-gradient-to-r from-[hsl(var(--accent))] to-[hsl(var(--primary))] bg-clip-text text-transparent">
                simplified.
              </span>
            </h2>
            <p className="text-[hsl(var(--sidebar-fg))] text-sm leading-relaxed max-w-md">
              Monitor trips, manage agents, track revenue — your complete transport management console.
            </p>
          </div>

          {/* Feature cards */}
          <div className="space-y-3">
            {features.map((feat, i) => (
              <motion.div
                key={feat.title}
                initial={{ opacity: 0, x: -20 }}
                animate={{ opacity: 1, x: 0 }}
                transition={{ duration: 0.4, delay: 0.4 + i * 0.12 }}
                className="flex items-start gap-4 p-4 rounded-xl bg-[hsl(var(--sidebar-accent)/0.4)] border border-[hsl(var(--sidebar-border))] backdrop-blur-sm"
              >
                <div className="h-9 w-9 rounded-lg bg-[hsl(var(--accent)/0.15)] flex items-center justify-center shrink-0">
                  <feat.icon className="h-4 w-4 text-[hsl(var(--accent))]" />
                </div>
                <div>
                  <p className="text-sm font-semibold text-[hsl(var(--sidebar-primary-foreground))]" style={{ fontFamily: 'var(--font-display)' }}>
                    {feat.title}
                  </p>
                  <p className="text-xs text-[hsl(var(--sidebar-fg))] mt-0.5 leading-relaxed">
                    {feat.desc}
                  </p>
                </div>
              </motion.div>
            ))}
          </div>
        </motion.div>

        {/* Footer */}
        <motion.p
          initial={{ opacity: 0 }}
          animate={{ opacity: 0.4 }}
          transition={{ delay: 0.8 }}
          className="relative z-10 text-[11px] text-[hsl(var(--sidebar-fg))]"
        >
          © 2025 BusTicket System • All rights reserved
        </motion.p>
      </div>

      {/* Right — login form */}
      <div className="flex-1 flex items-center justify-center px-5 py-10 sm:px-8 bg-background">
        <motion.div
          initial={{ opacity: 0, y: 16 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.5 }}
          className="w-full max-w-[380px]"
        >
          {/* Mobile logo */}
          <div className="flex items-center gap-3 mb-10 lg:hidden">
            <div className="h-10 w-10 rounded-xl bg-gradient-to-br from-[hsl(var(--primary))] to-[hsl(var(--accent))] flex items-center justify-center">
              <Bus className="h-5 w-5 text-primary-foreground" />
            </div>
            <span className="text-lg font-bold text-foreground" style={{ fontFamily: 'var(--font-display)' }}>BusTicket</span>
          </div>

          {/* Header */}
          <div className="mb-8">
            <h1 className="text-2xl font-bold text-foreground tracking-tight" style={{ fontFamily: 'var(--font-display)' }}>
              Sign in to your account
            </h1>
            <p className="text-sm text-muted-foreground mt-2">
              Enter your credentials to access the admin console
            </p>
          </div>

          {/* Error */}
          <ErrorAlert error={error} className="mb-5" />

          {/* Form */}
          <form onSubmit={handleLogin} className="space-y-5">
            <div className="space-y-1.5">
              <Label htmlFor="username" className="text-xs font-semibold uppercase tracking-wider text-muted-foreground">
                Username or Email
              </Label>
              <div className="relative group">
                <User className="absolute left-3.5 top-1/2 -translate-y-1/2 w-4 h-4 text-muted-foreground/50 group-focus-within:text-[hsl(var(--accent))] transition-colors" />
                <Input
                  id="username"
                  placeholder="Enter your username or email"
                  value={username}
                  onChange={(e) => { setUsername(e.target.value); clearError(); }}
                  className="pl-11 h-12 bg-muted/30 border-border/60 focus:bg-background focus:border-[hsl(var(--accent))] transition-all rounded-xl text-foreground"
                  required
                  disabled={isLoading}
                />
              </div>
            </div>

            <div className="space-y-1.5">
              <Label htmlFor="password" className="text-xs font-semibold uppercase tracking-wider text-muted-foreground">
                Password
              </Label>
              <div className="relative group">
                <Lock className="absolute left-3.5 top-1/2 -translate-y-1/2 w-4 h-4 text-muted-foreground/50 group-focus-within:text-[hsl(var(--accent))] transition-colors" />
                <Input
                  id="password"
                  type={showPassword ? "text" : "password"}
                  placeholder="••••••••"
                  value={password}
                  onChange={(e) => { setPassword(e.target.value); clearError(); }}
                  className="pl-11 pr-12 h-12 bg-muted/30 border-border/60 focus:bg-background focus:border-[hsl(var(--accent))] transition-all rounded-xl text-foreground appearance-none"
                  required
                  disabled={isLoading}
                />
                <button
                  type="button"
                  onClick={() => setShowPassword((value) => !value)}
                  className="absolute right-3 top-1/2 -translate-y-1/2 text-muted-foreground/70 hover:text-foreground transition-colors"
                  aria-label={showPassword ? "Hide password" : "Show password"}
                >
                  {showPassword ? <EyeOff className="h-4 w-4" /> : <Eye className="h-4 w-4" />}
                </button>
              </div>
            </div>

            <Button
              type="submit"
              className="w-full h-12 text-sm font-semibold rounded-xl shadow-lg shadow-primary/20 group"
              disabled={isLoading || !username.trim() || !password.trim()}
            >
              {isLoading ? (
                <span className="flex items-center gap-2">
                  <span className="h-4 w-4 border-2 border-primary-foreground/30 border-t-primary-foreground rounded-full animate-spin" />
                  Signing in…
                </span>
              ) : (
                <span className="flex items-center gap-2">
                  Sign In
                  <ArrowRight className="h-4 w-4 group-hover:translate-x-0.5 transition-transform" />
                </span>
              )}
            </Button>

            <Link
              to="/forgot-password"
              className="block text-center text-sm text-muted-foreground hover:text-[hsl(var(--accent))] font-medium transition-colors mt-4"
            >
              Forgot your password?
            </Link>
          </form>

          {/* Footer */}
          <div className="mt-8 pt-6 border-t border-border/50">
            <p className="text-xs text-muted-foreground text-center">
              Need access? Contact your system administrator.
            </p>
          </div>

          <p className="text-center text-[11px] text-muted-foreground/40 mt-8 lg:hidden">
            © 2025 BusTicket System
          </p>
        </motion.div>
      </div>
    </div>
  );
};

export default Login;
