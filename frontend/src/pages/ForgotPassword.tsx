import { useState, useEffect } from "react";
import { Link } from "react-router-dom";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Button } from "@/components/ui/button";
import { Bus, Mail, ArrowLeft, CheckCircle2, AlertCircle } from "lucide-react";
import { motion, AnimatePresence } from "framer-motion";
import ErrorAlert from "@/components/ErrorAlert";
import apiClient from "@/lib/api/axios";

interface ForgotPasswordResponse {
  accountExists: boolean;
  message: string;
}

// Rate limiting configuration
const RESEND_CONFIG = {
  MAX_ATTEMPTS: 5,
  WINDOW_HOURS: 24,
  INITIAL_DELAY_SECONDS: 60,
  STORAGE_KEY: 'forgotPasswordAttempts',
};

interface ResendAttempt {
  timestamp: number;
}

const getResendAttempts = (): ResendAttempt[] => {
  try {
    const stored = localStorage.getItem(RESEND_CONFIG.STORAGE_KEY);
    return stored ? JSON.parse(stored) : [];
  } catch {
    return [];
  }
};

const addResendAttempt = () => {
  const attempts = getResendAttempts();
  const now = Date.now();
  const recentAttempts = attempts.filter(
    (attempt) => now - attempt.timestamp < RESEND_CONFIG.WINDOW_HOURS * 60 * 60 * 1000
  );
  recentAttempts.push({ timestamp: now });
  localStorage.setItem(RESEND_CONFIG.STORAGE_KEY, JSON.stringify(recentAttempts));
  return recentAttempts;
};

const getExponentialDelay = (attemptCount: number): number => {
  // Exponential backoff: 60s, 120s, 240s, 480s, 960s
  return RESEND_CONFIG.INITIAL_DELAY_SECONDS * Math.pow(2, attemptCount - 1);
};

const formatCountdown = (totalSeconds: number): string => {
  if (totalSeconds < 60) return `${totalSeconds}s`;
  const minutes = Math.floor(totalSeconds / 60);
  const seconds = totalSeconds % 60;
  return seconds > 0 ? `${minutes}m ${seconds}s` : `${minutes}m`;
};

const getNextResendTime = (email: string): number | null => {
  const attempts = getResendAttempts();
  if (attempts.length === 0) return null;
  
  const lastAttempt = attempts[attempts.length - 1];
  const attemptCount = attempts.length;
  const delay = getExponentialDelay(attemptCount);
  const nextResendTime = lastAttempt.timestamp + delay * 1000;
  
  return nextResendTime > Date.now() ? nextResendTime : null;
};

const ForgotPassword = () => {
  const [email, setEmail] = useState("");
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [isSubmitted, setIsSubmitted] = useState(false);
  const [isResending, setIsResending] = useState(false);
  const [remainingSeconds, setRemainingSeconds] = useState(0);
  const [attemptsUsed, setAttemptsUsed] = useState(0);
  const [attemptsLimitReached, setAttemptsLimitReached] = useState(false);

  // Countdown timer — re-runs whenever attemptsUsed changes so it picks up the new delay
  useEffect(() => {
    if (!isSubmitted) return;

    const tick = () => {
      const nextResendTime = getNextResendTime(email);
      if (!nextResendTime) {
        setRemainingSeconds(0);
        return;
      }
      const secondsLeft = Math.ceil((nextResendTime - Date.now()) / 1000);
      setRemainingSeconds(secondsLeft > 0 ? secondsLeft : 0);
    };

    tick();
    const interval = setInterval(tick, 500);
    return () => clearInterval(interval);
  }, [isSubmitted, attemptsUsed, email]);

  const requestResetLink = async (currentEmail: string) => {
    const response = await apiClient.post<ForgotPasswordResponse>("/auth/forgot-password", { email: currentEmail });
    return response.data;
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError(null);
    const trimmedEmail = email.trim();
    if (!trimmedEmail) return;

    setIsLoading(true);
    try {
      const result = await requestResetLink(trimmedEmail);
      if (result.accountExists) {
        // Record this attempt
        const updatedAttempts = addResendAttempt();
        setAttemptsUsed(updatedAttempts.length);
        setAttemptsLimitReached(updatedAttempts.length >= RESEND_CONFIG.MAX_ATTEMPTS);
        setIsSubmitted(true);
      } else {
        setIsSubmitted(false);
        setError("We couldn't find an account with that email address.");
      }
    } catch (err: any) {
      setIsSubmitted(false);
      setError(err?.message || "Failed to send reset email.");
    } finally {
      setIsLoading(false);
    }
  };

  const handleResend = async () => {
    const trimmedEmail = email.trim();
    if (!trimmedEmail) {
      setError("Enter your email address first.");
      return;
    }

    // Check if rate limit is reached
    const attempts = getResendAttempts();
    if (attempts.length >= RESEND_CONFIG.MAX_ATTEMPTS) {
      setAttemptsLimitReached(true);
      setError(`You've reached the maximum number of resend attempts. Please try again in 24 hours.`);
      return;
    }

    // Check if still in cooldown
    const nextResendTime = getNextResendTime(trimmedEmail);
    if (nextResendTime) {
      const secondsLeft = Math.ceil((nextResendTime - Date.now()) / 1000);
      setError(`Please wait ${secondsLeft} seconds before requesting another email.`);
      return;
    }

    setError(null);
    setIsResending(true);
    try {
      const result = await requestResetLink(trimmedEmail);
      if (!result.accountExists) {
        setIsSubmitted(false);
        setError("We couldn't find an account with that email address.");
      } else {
        // Record this resend attempt
        const updatedAttempts = addResendAttempt();
        setAttemptsUsed(updatedAttempts.length);
        setAttemptsLimitReached(updatedAttempts.length >= RESEND_CONFIG.MAX_ATTEMPTS);
        setError(null);
      }
    } catch (err: any) {
      setError(err?.message || "Failed to resend reset email.");
    } finally {
      setIsResending(false);
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
        {/* Logo */}
        <div className="flex items-center gap-3 mb-10">
          <div className="h-10 w-10 rounded-xl bg-gradient-to-br from-[hsl(var(--primary))] to-[hsl(var(--accent))] flex items-center justify-center">
            <Bus className="h-5 w-5 text-primary-foreground" />
          </div>
          <span className="text-lg font-bold text-foreground" style={{ fontFamily: 'var(--font-display)' }}>
            CountryBoy
          </span>
        </div>

        <AnimatePresence mode="wait">
          {!isSubmitted ? (
            <motion.div
              key="form"
              initial={{ opacity: 0, y: 10 }}
              animate={{ opacity: 1, y: 0 }}
              exit={{ opacity: 0, y: -10 }}
              transition={{ duration: 0.3 }}
            >
              {/* Header */}
              <div className="mb-8">
                <h1 className="text-2xl font-bold text-foreground tracking-tight" style={{ fontFamily: 'var(--font-display)' }}>
                  Reset your password
                </h1>
                <p className="text-sm text-muted-foreground mt-2">
                  Enter your account email and we'll send you a link to reset your password.
                </p>
              </div>

              <ErrorAlert error={error} className="mb-5" />

              <form onSubmit={handleSubmit} className="space-y-5">
                <div className="space-y-1.5">
                  <Label htmlFor="email" className="text-xs font-semibold uppercase tracking-wider text-muted-foreground">
                    Email
                  </Label>
                  <div className="relative group">
                    <Mail className="absolute left-3.5 top-1/2 -translate-y-1/2 w-4 h-4 text-muted-foreground/50 group-focus-within:text-[hsl(var(--accent))] transition-colors" />
                    <Input
                      id="email"
                      type="email"
                      placeholder="you@example.com"
                      value={email}
                      onChange={(e) => { setEmail(e.target.value); setError(null); }}
                      className="pl-11 h-12 bg-muted/30 border-border/60 focus:bg-background focus:border-[hsl(var(--accent))] transition-all rounded-xl text-foreground"
                      required
                      disabled={isLoading}
                    />
                  </div>
                </div>

                <Button
                  type="submit"
                  className="w-full h-12 text-sm font-semibold rounded-xl shadow-lg shadow-primary/20"
                  disabled={isLoading || !email.trim()}
                >
                  {isLoading ? (
                    <span className="flex items-center gap-2">
                      <span className="h-4 w-4 border-2 border-primary-foreground/30 border-t-primary-foreground rounded-full animate-spin" />
                      Sending…
                    </span>
                  ) : (
                    "Send Reset Link"
                  )}
                </Button>
              </form>
            </motion.div>
          ) : (
            <motion.div
              key="success"
              initial={{ opacity: 0, y: 10 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ duration: 0.4 }}
              className="text-center space-y-4"
            >
              <div className="mx-auto h-14 w-14 rounded-full bg-[hsl(var(--success)/0.12)] flex items-center justify-center">
                <CheckCircle2 className="h-7 w-7 text-[hsl(var(--success))]" />
              </div>
              <h2 className="text-xl font-bold text-foreground" style={{ fontFamily: 'var(--font-display)' }}>
                Check your email
              </h2>
              <p className="text-sm text-muted-foreground max-w-xs mx-auto">
                A password reset link was sent to <strong className="text-foreground">{email}</strong>.
              </p>

              {/* Rate limit warning */}
              {attemptsLimitReached && (
                <div className="mt-3 p-3 rounded-lg bg-destructive/10 border border-destructive/30 flex gap-2">
                  <AlertCircle className="h-4 w-4 text-destructive mt-0.5 shrink-0" />
                  <p className="text-xs text-destructive">
                    Maximum resend attempts reached. Please try again in 24 hours.
                  </p>
                </div>
              )}

              <div className="flex flex-col gap-3 pt-2">
                <Button
                  variant="outline"
                  className="rounded-xl"
                  onClick={handleResend}
                  disabled={isResending || attemptsLimitReached || remainingSeconds > 0}
                >
                  {isResending ? (
                    "Resending..."
                  ) : remainingSeconds > 0 ? (
                    `Resend email in ${formatCountdown(remainingSeconds)}`
                  ) : attemptsLimitReached ? (
                    "Resend limit reached"
                  ) : (
                    "Resend email"
                  )}
                </Button>
                <Button
                  variant="outline"
                  className="rounded-xl"
                  onClick={() => { setIsSubmitted(false); setEmail(""); setError(null); setRemainingSeconds(0); }}
                >
                  Try another email address
                </Button>
              </div>
            </motion.div>
          )}
        </AnimatePresence>

        {/* Back to login */}
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

export default ForgotPassword;
