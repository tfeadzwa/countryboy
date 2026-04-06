import { useMemo, useState } from "react";
import { Link, useNavigate, useSearchParams } from "react-router-dom";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Button } from "@/components/ui/button";
import { Bus, Lock, ArrowLeft, CheckCircle2, Eye, EyeOff } from "lucide-react";
import { motion } from "framer-motion";
import ErrorAlert from "@/components/ErrorAlert";
import apiClient from "@/lib/api/axios";

const ResetPassword = () => {
  const navigate = useNavigate();
  const [searchParams] = useSearchParams();
  const token = useMemo(() => searchParams.get("token") || "", [searchParams]);

  const [newPassword, setNewPassword] = useState("");
  const [confirmPassword, setConfirmPassword] = useState("");
  const [isLoading, setIsLoading] = useState(false);
  const [isSubmitted, setIsSubmitted] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [showNewPassword, setShowNewPassword] = useState(false);
  const [showConfirmPassword, setShowConfirmPassword] = useState(false);

  const passwordChecks = {
    minLength: newPassword.length >= 8,
    uppercase: /[A-Z]/.test(newPassword),
    lowercase: /[a-z]/.test(newPassword),
    number: /\d/.test(newPassword),
    special: /[^A-Za-z0-9]/.test(newPassword),
  };

  const passwordScore = Object.values(passwordChecks).filter(Boolean).length;
  const passwordStrength =
    passwordScore <= 2 ? "Weak" : passwordScore <= 4 ? "Medium" : "Strong";

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError(null);

    if (!token) {
      setError("Reset token is missing. Please request a new password reset link.");
      return;
    }

    if (newPassword.length < 8) {
      setError("Password must be at least 8 characters.");
      return;
    }

    if (newPassword !== confirmPassword) {
      setError("Passwords do not match.");
      return;
    }

    try {
      setIsLoading(true);
      await apiClient.post("/auth/reset-password", {
        token,
        new_password: newPassword,
      });
      setIsSubmitted(true);
      setTimeout(() => navigate("/login"), 1800);
    } catch (err: any) {
      setError(err?.message || "Failed to reset password.");
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <div className="min-h-screen flex items-center justify-center px-5 py-10 sm:px-8 bg-background">
      <motion.div
        initial={{ opacity: 0, y: 16 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.5 }}
        className="w-full max-w-[420px]"
      >
        <div className="flex items-center gap-3 mb-10">
          <div className="h-10 w-10 rounded-xl bg-gradient-to-br from-[hsl(var(--primary))] to-[hsl(var(--accent))] flex items-center justify-center">
            <Bus className="h-5 w-5 text-primary-foreground" />
          </div>
          <span className="text-lg font-bold text-foreground" style={{ fontFamily: "var(--font-display)" }}>
            CountryBoy
          </span>
        </div>

        {!isSubmitted ? (
          <>
            <div className="mb-8">
              <h1 className="text-2xl font-bold text-foreground tracking-tight" style={{ fontFamily: "var(--font-display)" }}>
                Create a new password
              </h1>
              <p className="text-sm text-muted-foreground mt-2">
                Enter your new password below.
              </p>
              <p className="text-xs text-muted-foreground mt-2 leading-5">
                Use at least 8 characters with uppercase, lowercase, a number, and a special character.
              </p>
            </div>

            <ErrorAlert error={error} className="mb-5" />

            <form onSubmit={handleSubmit} className="space-y-5">
              <div className="space-y-1.5">
                <Label htmlFor="newPassword" className="text-xs font-semibold uppercase tracking-wider text-muted-foreground">
                  New password
                </Label>
                <div className="relative group">
                  <Lock className="absolute left-3.5 top-1/2 -translate-y-1/2 w-4 h-4 text-muted-foreground/50 group-focus-within:text-[hsl(var(--accent))] transition-colors" />
                  <Input
                    id="newPassword"
                    type={showNewPassword ? "text" : "password"}
                    placeholder="At least 8 characters"
                    value={newPassword}
                    onChange={(e) => { setNewPassword(e.target.value); setError(null); }}
                    className="pl-11 pr-12 h-12 bg-muted/30 border-border/60 focus:bg-background focus:border-[hsl(var(--accent))] transition-all rounded-xl text-foreground"
                    required
                    disabled={isLoading}
                  />
                  <button
                    type="button"
                    onClick={() => setShowNewPassword((value) => !value)}
                    className="absolute right-3 top-1/2 -translate-y-1/2 text-muted-foreground/70 hover:text-foreground transition-colors"
                    aria-label={showNewPassword ? "Hide password" : "Show password"}
                  >
                    {showNewPassword ? <EyeOff className="h-4 w-4" /> : <Eye className="h-4 w-4" />}
                  </button>
                </div>
                <div className="space-y-1 pt-1">
                  <p className="text-xs font-medium text-muted-foreground">
                    Password strength: <span className="text-foreground">{passwordStrength}</span>
                  </p>
                  <div className="grid grid-cols-5 gap-1">
                    {Array.from({ length: 5 }).map((_, index) => (
                      <span
                        key={index}
                        className={`h-1.5 rounded-full ${
                          index < passwordScore ? "bg-[hsl(var(--success))]" : "bg-muted"
                        }`}
                      />
                    ))}
                  </div>
                  <ul className="text-xs text-muted-foreground space-y-0.5">
                    <li>{passwordChecks.minLength ? "✓" : "•"} At least 8 characters</li>
                    <li>{passwordChecks.uppercase ? "✓" : "•"} One uppercase letter</li>
                    <li>{passwordChecks.lowercase ? "✓" : "•"} One lowercase letter</li>
                    <li>{passwordChecks.number ? "✓" : "•"} One number</li>
                    <li>{passwordChecks.special ? "✓" : "•"} One special character</li>
                  </ul>
                </div>
              </div>

              <div className="space-y-1.5">
                <Label htmlFor="confirmPassword" className="text-xs font-semibold uppercase tracking-wider text-muted-foreground">
                  Confirm password
                </Label>
                <div className="relative group">
                  <Lock className="absolute left-3.5 top-1/2 -translate-y-1/2 w-4 h-4 text-muted-foreground/50 group-focus-within:text-[hsl(var(--accent))] transition-colors" />
                  <Input
                    id="confirmPassword"
                    type={showConfirmPassword ? "text" : "password"}
                    placeholder="Re-enter your password"
                    value={confirmPassword}
                    onChange={(e) => { setConfirmPassword(e.target.value); setError(null); }}
                    className="pl-11 pr-12 h-12 bg-muted/30 border-border/60 focus:bg-background focus:border-[hsl(var(--accent))] transition-all rounded-xl text-foreground"
                    required
                    disabled={isLoading}
                  />
                  <button
                    type="button"
                    onClick={() => setShowConfirmPassword((value) => !value)}
                    className="absolute right-3 top-1/2 -translate-y-1/2 text-muted-foreground/70 hover:text-foreground transition-colors"
                    aria-label={showConfirmPassword ? "Hide password" : "Show password"}
                  >
                    {showConfirmPassword ? <EyeOff className="h-4 w-4" /> : <Eye className="h-4 w-4" />}
                  </button>
                </div>
              </div>

              <Button
                type="submit"
                className="w-full h-12 text-sm font-semibold rounded-xl shadow-lg shadow-primary/20"
                disabled={isLoading || !newPassword || !confirmPassword}
              >
                {isLoading ? (
                  <span className="flex items-center gap-2">
                    <span className="h-4 w-4 border-2 border-primary-foreground/30 border-t-primary-foreground rounded-full animate-spin" />
                    Resetting…
                  </span>
                ) : (
                  "Reset Password"
                )}
              </Button>
            </form>
          </>
        ) : (
          <div className="text-center space-y-4">
            <div className="mx-auto h-14 w-14 rounded-full bg-[hsl(var(--success)/0.12)] flex items-center justify-center">
              <CheckCircle2 className="h-7 w-7 text-[hsl(var(--success))]" />
            </div>
            <h2 className="text-xl font-bold text-foreground" style={{ fontFamily: "var(--font-display)" }}>
              Password updated
            </h2>
            <p className="text-sm text-muted-foreground max-w-xs mx-auto">
              Your password has been reset successfully. Redirecting you to sign in.
            </p>
          </div>
        )}

        <div className="mt-8 pt-6 border-t border-border/50">
          <Link
            to="/login"
            className="flex items-center justify-center gap-2 text-sm text-muted-foreground hover:text-foreground transition-colors"
          >
            <ArrowLeft className="h-4 w-4" />
            Back to sign in
          </Link>
        </div>
      </motion.div>
    </div>
  );
};

export default ResetPassword;
