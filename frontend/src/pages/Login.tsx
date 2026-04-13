import { useState, useEffect } from "react";
import { useNavigate, Link } from "react-router-dom";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Button } from "@/components/ui/button";
import { Lock, User, ArrowRight, Shield, Zap, BarChart3, Eye, EyeOff, MapPin } from "lucide-react";
import { motion } from "framer-motion";
import { useAuth } from "@/contexts/AuthContext";
import ErrorAlert from "@/components/ErrorAlert";
import loginHeroBus from "@/assets/login-hero-bus.jpg";
import cboyLogo from "@/assets/cboy-logo.svg";

// CSS filter removed — SVG uses built-in colour groups (black / red / white)

const adminHighlights = [
  { icon: Shield,    label: "Role-Based Access",    desc: "Superadmin & depot-level controls" },
  { icon: BarChart3, label: "Revenue & Analytics",  desc: "Trip, ticket and agent reporting" },
  { icon: Zap,       label: "Multi-Depot Console",  desc: "Manage all depots from one place" },
];

const Login = () => {
  const navigate = useNavigate();
  const { login, isAuthenticated, isLoading, error, clearError } = useAuth();
  const [username, setUsername] = useState("");
  const [password, setPassword] = useState("");
  const [showPassword, setShowPassword] = useState(false);

  useEffect(() => {
    if (isAuthenticated) navigate("/");
  }, [isAuthenticated, navigate]);

  const handleLogin = async (e: React.FormEvent) => {
    e.preventDefault();
    clearError();
    if (!username.trim() || !password.trim()) return;
    await login({ username: username.trim(), password });
  };

  return (
    <div className="min-h-screen flex flex-col lg:flex-row">

      {/* ── LEFT PANEL: full-bleed bus photo ── */}
      <div className="hidden lg:flex lg:w-[58%] relative overflow-hidden">

        {/* Bus background photo */}
        <img
          src={loginHeroBus}
          alt="Country Boy bus"
          className="absolute inset-0 w-full h-full object-cover object-center scale-105"
          style={{ filter: 'brightness(0.68) saturate(1.2) contrast(1.05)' }}
        />

        {/* Layered gradients — darken top + bottom, leave centre clear for the bus */}
        <div className="absolute inset-0 bg-gradient-to-b from-black/75 via-transparent via-40% to-black/85" />
        {/* Subtle warm tint on the left edge matching brand livery */}
        <div className="absolute inset-y-0 left-0 w-1.5 bg-gradient-to-b from-red-600 via-yellow-500 to-red-700" />

        {/* Content — three zones: top, (bus shows through middle), bottom */}
        <div className="relative z-10 flex flex-col justify-between w-full h-full p-8 xl:p-12">

          {/* ── TOP ZONE: logo + status + headline ── */}
          <div className="space-y-6">
            {/* Logo */}
            <motion.div
              initial={{ opacity: 0, y: -12 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ duration: 0.55 }}
              className="space-y-2"
            >
              <img
                src={cboyLogo}
                alt="Country Boy"
                className="h-12 w-auto"
              />
              <p className="text-[11px] font-semibold text-white/50 uppercase tracking-[0.22em]" style={{ fontFamily: 'var(--font-display)' }}>
                Transport Management
              </p>
            </motion.div>

            {/* Status pill */}
            <motion.div
              initial={{ opacity: 0, x: -10 }}
              animate={{ opacity: 1, x: 0 }}
              transition={{ duration: 0.45, delay: 0.1 }}
              className="inline-flex items-center gap-2 px-3 py-1.5 rounded-full bg-black/30 border border-white/15 backdrop-blur-md w-fit"
            >
              <span className="h-1.5 w-1.5 rounded-full bg-emerald-400 animate-pulse" />
              <span className="text-xs font-medium text-white/85">System Operational</span>
            </motion.div>

            {/* Headline */}
            <motion.div
              initial={{ opacity: 0, y: 16 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ duration: 0.6, delay: 0.18 }}
              className="space-y-2"
            >
              <h2 className="text-4xl xl:text-[2.75rem] font-black text-white leading-[1.1] tracking-tight" style={{ fontFamily: 'var(--font-display)' }}>
                Fleet operations,{" "}
                <span className="text-transparent bg-clip-text bg-gradient-to-r from-yellow-400 to-red-400">
                  simplified.
                </span>
              </h2>
              <p className="text-white/85 text-sm leading-relaxed max-w-xs" style={{ textShadow: '0 1px 8px rgba(0,0,0,0.7)' }}>
                Monitor trips, manage agents and track revenue — one console for your entire fleet.
              </p>
            </motion.div>
          </div>

          {/* ── MIDDLE ZONE: intentionally empty — bus shows through ── */}
          <div />

          {/* ── BOTTOM ZONE: feature badges + footer ── */}
          <div className="space-y-4">
            {/* Feature badge row */}
            <motion.div
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ duration: 0.55, delay: 0.35 }}
              className="flex gap-2.5 flex-wrap"
            >
              {adminHighlights.map((h) => (
                <div
                  key={h.label}
                  className="flex items-center gap-2 px-3 py-2 rounded-xl bg-black/40 border border-white/12 backdrop-blur-md"
                >
                  <div className="h-6 w-6 rounded-md bg-yellow-500/20 flex items-center justify-center shrink-0">
                    <h.icon className="h-3.5 w-3.5 text-yellow-400" />
                  </div>
                  <span className="text-xs font-semibold text-white/85 whitespace-nowrap">{h.label}</span>
                </div>
              ))}
            </motion.div>

            {/* Footer */}
            <motion.div
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              transition={{ delay: 0.9 }}
              className="flex items-center gap-2 text-[11px] text-white/30"
            >
              <MapPin className="h-3 w-3 shrink-0" />
              <span>Zimbabwe • © {new Date().getFullYear()} Country Boy Transport</span>
            </motion.div>
          </div>
        </div>
      </div>

      {/* ── RIGHT PANEL: login form ── */}
      <div className="flex-1 flex items-center justify-center px-5 py-10 sm:px-8 bg-background relative overflow-hidden">
        {/* Subtle decorative blob */}
        <div className="absolute -top-32 -right-32 w-80 h-80 rounded-full opacity-[0.04] blur-3xl bg-red-500 pointer-events-none" />
        <div className="absolute -bottom-32 -left-32 w-80 h-80 rounded-full opacity-[0.04] blur-3xl bg-yellow-500 pointer-events-none" />

        <motion.div
          initial={{ opacity: 0, y: 18 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.5 }}
          className="w-full max-w-[400px]"
        >
          {/* Mobile logo */}
          <div className="mb-10 lg:hidden space-y-1.5">
            <img
              src={cboyLogo}
              alt="Country Boy"
              className="h-10 w-auto"
              style={{ filter: 'brightness(0) saturate(100%) invert(17%) sepia(83%) saturate(2600%) hue-rotate(347deg) brightness(92%)' }}
            />
            <p className="text-[10px] font-semibold text-foreground/60 uppercase tracking-[0.2em]" style={{ fontFamily: 'var(--font-display)' }}>
              Transport Management
            </p>
          </div>

          {/* Header */}
          <div className="mb-8 space-y-1">
            <h1 className="text-2xl font-bold text-foreground tracking-tight" style={{ fontFamily: 'var(--font-display)' }}>
              Welcome back
            </h1>
            <p className="text-sm text-muted-foreground">
              Sign in to access the admin console 
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
                <User className="absolute left-3.5 top-1/2 -translate-y-1/2 w-4 h-4 text-muted-foreground/50 group-focus-within:text-red-500 transition-colors" />
                <Input
                  id="username"
                  placeholder="Enter your username or email"
                  value={username}
                  onChange={(e) => { setUsername(e.target.value); clearError(); }}
                  className="pl-11 h-12 bg-muted/30 border-border/60 focus:bg-background focus:border-red-500 focus:ring-red-500/20 transition-all rounded-xl text-foreground"
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
                <Lock className="absolute left-3.5 top-1/2 -translate-y-1/2 w-4 h-4 text-muted-foreground/50 group-focus-within:text-red-500 transition-colors" />
                <Input
                  id="password"
                  type={showPassword ? "text" : "password"}
                  placeholder="••••••••"
                  value={password}
                  onChange={(e) => { setPassword(e.target.value); clearError(); }}
                  className="pl-11 pr-12 h-12 bg-muted/30 border-border/60 focus:bg-background focus:border-red-500 focus:ring-red-500/20 transition-all rounded-xl text-foreground appearance-none"
                  required
                  disabled={isLoading}
                />
                <button
                  type="button"
                  onClick={() => setShowPassword((v) => !v)}
                  className="absolute right-3 top-1/2 -translate-y-1/2 text-muted-foreground/70 hover:text-foreground transition-colors"
                  aria-label={showPassword ? "Hide password" : "Show password"}
                >
                  {showPassword ? <EyeOff className="h-4 w-4" /> : <Eye className="h-4 w-4" />}
                </button>
              </div>
            </div>

            {/* Forgot password link — right-aligned above button */}
            <div className="flex justify-end -mt-2">
              <Link
                to="/forgot-password"
                className="text-xs text-muted-foreground hover:text-red-500 font-medium transition-colors"
              >
                Forgot password?
              </Link>
            </div>

            <Button
              type="submit"
              className="w-full h-12 text-sm font-semibold rounded-xl shadow-lg group bg-gradient-to-r from-red-600 to-red-500 hover:from-red-700 hover:to-red-600 border-0 text-white shadow-red-600/25"
              disabled={isLoading || !username.trim() || !password.trim()}
            >
              {isLoading ? (
                <span className="flex items-center gap-2">
                  <span className="h-4 w-4 border-2 border-white/30 border-t-white rounded-full animate-spin" />
                  Signing in…
                </span>
              ) : (
                <span className="flex items-center gap-2">
                  Sign In
                  <ArrowRight className="h-4 w-4 group-hover:translate-x-0.5 transition-transform" />
                </span>
              )}
            </Button>
          </form>

          {/* Footer */}
          <div className="mt-8 pt-6 border-t border-border/50 text-center space-y-1">
            <p className="text-xs text-muted-foreground">
              Need access? Contact your system administrator.
            </p>
            <p className="text-[11px] text-muted-foreground/40">
              © {new Date().getFullYear()} Country Boy Transport
            </p>
          </div>
        </motion.div>
      </div>
    </div>
  );
};

export default Login;
