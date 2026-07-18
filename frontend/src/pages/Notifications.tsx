import { motion, AnimatePresence } from "framer-motion";
import { useCallback, useEffect, useMemo, useState } from "react";
import { useNavigate } from "react-router-dom";
import PageHeader from "@/components/PageHeader";
import { Card, CardContent } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { Tabs, TabsList, TabsTrigger } from "@/components/ui/tabs";
import {
  Bell,
  CheckCheck,
  AlertTriangle,
  Info,
  Bus,
  Trash2,
  Clock,
  Loader2,
  ShieldAlert,
  CalendarDays,
  RefreshCw,
} from "lucide-react";
import { notificationService } from "@/lib/api/notification.service";
import { frequencyStyles, severityStyles } from "@/lib/fleet-compliance";
import type { AlertFrequency, FleetComplianceNotification } from "@/types";
import ErrorAlert from "@/components/ErrorAlert";

const DISMISSED_KEY = "cboy_dismissed_notifications";
const READ_KEY = "cboy_read_notifications";

function loadSet(key: string): Set<string> {
  try {
    const raw = localStorage.getItem(key);
    if (!raw) return new Set();
    const arr = JSON.parse(raw);
    return new Set(Array.isArray(arr) ? arr : []);
  } catch {
    return new Set();
  }
}

function saveSet(key: string, set: Set<string>) {
  localStorage.setItem(key, JSON.stringify([...set]));
}

type FilterTab = "all" | "daily" | "weekly" | "monthly" | "unread";

const containerVariants = {
  hidden: { opacity: 0 },
  visible: { opacity: 1, transition: { staggerChildren: 0.05 } },
};

const itemVariants = {
  hidden: { opacity: 0, y: 12, scale: 0.98 },
  visible: {
    opacity: 1,
    y: 0,
    scale: 1,
    transition: { duration: 0.35, ease: [0.25, 0.46, 0.45, 0.94] as [number, number, number, number] },
  },
  exit: { opacity: 0, x: -20, scale: 0.95, transition: { duration: 0.2 } },
};

function FrequencyIcon({ frequency }: { frequency: AlertFrequency }) {
  if (frequency === "daily") return <ShieldAlert className="h-[18px] w-[18px]" />;
  if (frequency === "weekly") return <AlertTriangle className="h-[18px] w-[18px]" />;
  return <Info className="h-[18px] w-[18px]" />;
}

const Notifications = () => {
  const navigate = useNavigate();
  const [notifications, setNotifications] = useState<FleetComplianceNotification[]>([]);
  const [summary, setSummary] = useState({
    total: 0,
    urgent: 0,
    warning: 0,
    monthly: 0,
    weekly: 0,
    daily: 0,
    attention_count: 0,
  });
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [filter, setFilter] = useState<FilterTab>("all");
  const [dismissed, setDismissed] = useState<Set<string>>(() => loadSet(DISMISSED_KEY));
  const [read, setRead] = useState<Set<string>>(() => loadSet(READ_KEY));

  const fetchNotifications = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const data = await notificationService.getAll();
      setNotifications(Array.isArray(data?.notifications) ? data.notifications : []);
      setSummary({
        total: data?.summary?.total ?? 0,
        urgent: data?.summary?.urgent ?? 0,
        warning: data?.summary?.warning ?? 0,
        monthly: data?.summary?.monthly ?? 0,
        weekly: data?.summary?.weekly ?? 0,
        daily: data?.summary?.daily ?? 0,
        attention_count: data?.summary?.attention_count ?? 0,
      });
    } catch (err) {
      setError(err instanceof Error ? err.message : "Failed to load notifications");
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    fetchNotifications();
  }, [fetchNotifications]);

  const visible = useMemo(
    () => notifications.filter((n) => !dismissed.has(n.id)),
    [notifications, dismissed]
  );

  const unreadCount = useMemo(
    () =>
      visible.filter(
        (n) =>
          !read.has(n.id) &&
          (n.severity === "expired" || n.severity === "urgent" || n.severity === "warning")
      ).length,
    [visible, read]
  );

  const filtered = useMemo(() => {
    return visible.filter((n) => {
      if (filter === "daily") return n.frequency === "daily";
      if (filter === "weekly") return n.frequency === "weekly";
      if (filter === "monthly") return n.frequency === "monthly";
      if (filter === "unread") {
        return (
          !read.has(n.id) &&
          (n.severity === "expired" || n.severity === "urgent" || n.severity === "warning")
        );
      }
      return true;
    });
  }, [visible, filter, read]);

  const markAllRead = () => {
    const next = new Set(read);
    visible.forEach((n) => next.add(n.id));
    setRead(next);
    saveSet(READ_KEY, next);
  };

  const toggleRead = (id: string) => {
    const next = new Set(read);
    if (next.has(id)) next.delete(id);
    else next.add(id);
    setRead(next);
    saveSet(READ_KEY, next);
  };

  const dismiss = (id: string) => {
    const next = new Set(dismissed);
    next.add(id);
    setDismissed(next);
    saveSet(DISMISSED_KEY, next);
  };

  return (
    <motion.div initial={{ opacity: 0 }} animate={{ opacity: 1 }} transition={{ duration: 0.3 }}>
      <PageHeader
        title="Notifications"
        description={
          unreadCount > 0
            ? `${unreadCount} compliance alert${unreadCount !== 1 ? "s" : ""} need attention`
            : "Fleet compliance expiry alerts"
        }
      >
        <div className="flex items-center gap-2">
          <Button
            variant="outline"
            size="sm"
            onClick={fetchNotifications}
            disabled={loading}
            className="gap-2 shadow-sm"
          >
            <RefreshCw className={`h-4 w-4 ${loading ? "animate-spin" : ""}`} />
            Refresh
          </Button>
          <Button
            variant="outline"
            size="sm"
            onClick={markAllRead}
            disabled={unreadCount === 0}
            className="gap-2 shadow-sm"
          >
            <CheckCheck className="h-4 w-4" />
            Mark all read
          </Button>
        </div>
      </PageHeader>

      <div className="mx-auto w-full max-w-3xl">
      {/* Summary chips */}
      <div className="grid grid-cols-2 sm:grid-cols-4 gap-2.5 mb-6">
        <Card className="shadow-none border-border/60 bg-destructive/5">
          <CardContent className="py-3 px-3.5 flex items-center gap-2.5">
            <div className="h-8 w-8 rounded-lg bg-destructive/10 flex items-center justify-center">
              <ShieldAlert className="h-4 w-4 text-destructive" />
            </div>
            <div>
              <p className="text-lg font-display font-bold leading-none text-foreground">
                {summary.daily}
              </p>
              <p className="text-[10px] text-muted-foreground mt-1 uppercase tracking-wide">
                Daily alerts
              </p>
            </div>
          </CardContent>
        </Card>
        <Card className="shadow-none border-border/60 bg-amber-500/5">
          <CardContent className="py-3 px-3.5 flex items-center gap-2.5">
            <div className="h-8 w-8 rounded-lg bg-amber-500/10 flex items-center justify-center">
              <AlertTriangle className="h-4 w-4 text-amber-600" />
            </div>
            <div>
              <p className="text-lg font-display font-bold leading-none text-foreground">
                {summary.weekly}
              </p>
              <p className="text-[10px] text-muted-foreground mt-1 uppercase tracking-wide">
                Weekly alerts
              </p>
            </div>
          </CardContent>
        </Card>
        <Card className="shadow-none border-border/60 bg-success/5">
          <CardContent className="py-3 px-3.5 flex items-center gap-2.5">
            <div className="h-8 w-8 rounded-lg bg-success/10 flex items-center justify-center">
              <CalendarDays className="h-4 w-4 text-success" />
            </div>
            <div>
              <p className="text-lg font-display font-bold leading-none text-foreground">
                {summary.monthly}
              </p>
              <p className="text-[10px] text-muted-foreground mt-1 uppercase tracking-wide">
                Monthly checks
              </p>
            </div>
          </CardContent>
        </Card>
        <Card className="shadow-none border-border/60">
          <CardContent className="py-3 px-3.5 flex items-center gap-2.5">
            <div className="h-8 w-8 rounded-lg bg-primary/10 flex items-center justify-center">
              <Bus className="h-4 w-4 text-primary" />
            </div>
            <div>
              <p className="text-lg font-display font-bold leading-none text-foreground">
                {summary.attention_count}
              </p>
              <p className="text-[10px] text-muted-foreground mt-1 uppercase tracking-wide">
                Need attention
              </p>
            </div>
          </CardContent>
        </Card>
      </div>

      <Tabs value={filter} onValueChange={(v) => setFilter(v as FilterTab)} className="mb-6">
        <TabsList className="bg-muted/50 p-1 flex flex-wrap h-auto gap-0.5">
          <TabsTrigger value="all" className="text-xs font-medium">
            All ({visible.length})
          </TabsTrigger>
          <TabsTrigger value="unread" className="text-xs font-medium">
            Unread ({unreadCount})
          </TabsTrigger>
          <TabsTrigger value="daily" className="text-xs font-medium">
            Daily ({summary.daily})
          </TabsTrigger>
          <TabsTrigger value="weekly" className="text-xs font-medium">
            Weekly ({summary.weekly})
          </TabsTrigger>
          <TabsTrigger value="monthly" className="text-xs font-medium">
            Monthly ({summary.monthly})
          </TabsTrigger>
        </TabsList>
      </Tabs>

      <ErrorAlert error={error} />

      {loading ? (
        <div className="flex items-center justify-center py-16">
          <Loader2 className="h-8 w-8 animate-spin text-muted-foreground" />
        </div>
      ) : (
        <AnimatePresence mode="popLayout">
          {filtered.length === 0 ? (
            <motion.div
              key="empty"
              initial={{ opacity: 0, scale: 0.95 }}
              animate={{ opacity: 1, scale: 1 }}
              className="flex flex-col items-center justify-center py-20 text-center"
            >
              <div className="h-14 w-14 rounded-2xl bg-muted/60 flex items-center justify-center mb-4">
                <Bell className="h-6 w-6 text-muted-foreground/50" />
              </div>
              <p className="text-sm font-semibold text-muted-foreground">No notifications</p>
              <p className="text-xs text-muted-foreground/60 mt-1">
                Fleet compliance is looking good for this filter.
              </p>
            </motion.div>
          ) : (
            <motion.div
              variants={containerVariants}
              initial="hidden"
              animate="visible"
              className="space-y-2.5"
            >
              {filtered.map((n) => {
                const isRead = read.has(n.id);
                const styles = severityStyles[n.severity] || severityStyles.info;
                return (
                  <motion.div key={n.id} variants={itemVariants} exit={itemVariants.exit} layout>
                    <Card
                      className={`group relative overflow-hidden transition-all duration-200 hover:shadow-md cursor-pointer ${
                        !isRead
                          ? "bg-card shadow-sm ring-1 ring-border"
                          : "bg-muted/20 shadow-none"
                      }`}
                      onClick={() => navigate("/fleets")}
                    >
                      {!isRead && (
                        <div className={`absolute left-0 top-0 bottom-0 w-1 rounded-l-lg ${styles.bar}`} />
                      )}

                      <CardContent className="flex items-start gap-4 py-4 pl-5 pr-4">
                        <div
                          className={`h-10 w-10 rounded-xl flex items-center justify-center shrink-0 ${styles.iconBg} ring-1 ${styles.ring}`}
                        >
                          <span className={styles.iconText}>
                            <FrequencyIcon frequency={n.frequency} />
                          </span>
                        </div>

                        <div className="flex-1 min-w-0">
                          <div className="flex items-center gap-2 flex-wrap mb-0.5">
                            <p
                              className={`text-sm leading-tight ${
                                !isRead
                                  ? "font-semibold text-foreground"
                                  : "font-medium text-muted-foreground"
                              }`}
                            >
                              {n.title}
                            </p>
                            {!isRead && (
                              <span className={`h-2 w-2 rounded-full shrink-0 animate-pulse ${styles.bar}`} />
                            )}
                            <Badge
                              variant="outline"
                              className={`text-[10px] capitalize ${frequencyStyles[n.frequency]}`}
                            >
                              {n.frequency_label}
                            </Badge>
                            {(n.severity === "expired" || n.severity === "urgent") && (
                              <Badge variant="outline" className={`text-[10px] ${styles.badge}`}>
                                {n.severity === "expired" ? "Expired" : "Urgent"}
                              </Badge>
                            )}
                          </div>
                          <p className="text-xs text-muted-foreground/80 leading-relaxed line-clamp-2">
                            {n.message}
                          </p>
                          <div className="flex items-center gap-3 mt-2 flex-wrap">
                            <div className="flex items-center gap-1">
                              <Clock className="h-3 w-3 text-muted-foreground/50" />
                              <span className="text-[11px] text-muted-foreground/60 font-medium">
                                {n.time}
                              </span>
                            </div>
                            {n.depot_name && (
                              <span className="text-[11px] text-muted-foreground/50">
                                {n.depot_name}
                              </span>
                            )}
                            {n.expiry_date && (
                              <span className="text-[11px] text-muted-foreground/50 font-mono">
                                Exp {n.expiry_date.slice(0, 10)}
                              </span>
                            )}
                          </div>
                        </div>

                        <div className="flex items-center gap-1 shrink-0 md:opacity-0 md:group-hover:opacity-100 transition-opacity duration-200">
                          <Button
                            variant="ghost"
                            size="icon"
                            className="h-8 w-8 text-muted-foreground hover:text-foreground"
                            onClick={(e) => {
                              e.stopPropagation();
                              toggleRead(n.id);
                            }}
                            title={isRead ? "Mark unread" : "Mark read"}
                          >
                            <CheckCheck className="h-3.5 w-3.5" />
                          </Button>
                          <Button
                            variant="ghost"
                            size="icon"
                            className="h-8 w-8 text-muted-foreground hover:text-destructive"
                            onClick={(e) => {
                              e.stopPropagation();
                              dismiss(n.id);
                            }}
                            title="Dismiss"
                          >
                            <Trash2 className="h-3.5 w-3.5" />
                          </Button>
                        </div>
                      </CardContent>
                    </Card>
                  </motion.div>
                );
              })}
            </motion.div>
          )}
        </AnimatePresence>
      )}
      </div>
    </motion.div>
  );
};

export default Notifications;
