import { motion, AnimatePresence } from "framer-motion";
import PageHeader from "@/components/PageHeader";
import { Card, CardContent } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Bell, CheckCheck, AlertTriangle, Info, Ticket, Bus, Trash2, Clock } from "lucide-react";
import { useState } from "react";
import { Tabs, TabsList, TabsTrigger } from "@/components/ui/tabs";

interface Notification {
  id: string;
  title: string;
  message: string;
  type: "info" | "warning" | "success";
  time: string;
  read: boolean;
  icon: typeof Bell;
}

const initialNotifications: Notification[] = [
  { id: "1", title: "Trip Delayed", message: "Trip #TR-1042 Harare→Bulawayo has been delayed by 45 minutes.", type: "warning", time: "10 min ago", read: false, icon: Bus },
  { id: "2", title: "New Agent Registered", message: "Agent Tendai Moyo has been registered at Harare Central depot.", type: "info", time: "1 hr ago", read: false, icon: Info },
  { id: "3", title: "High Sales Alert", message: "Today's ticket sales exceeded $5,000 USD — a new daily record!", type: "success", time: "3 hrs ago", read: false, icon: Ticket },
  { id: "4", title: "Fleet Maintenance Due", message: "Vehicle ZB-4821 is due for scheduled maintenance tomorrow.", type: "warning", time: "5 hrs ago", read: true, icon: AlertTriangle },
  { id: "5", title: "System Update", message: "System will be updated tonight at 02:00 AM CAT. Expect 5 min downtime.", type: "info", time: "Yesterday", read: true, icon: Info },
];

const typeConfig = {
  info: { bg: "bg-accent/10", text: "text-accent", ring: "ring-accent/20" },
  warning: { bg: "bg-warning/10", text: "text-warning", ring: "ring-warning/20" },
  success: { bg: "bg-success/10", text: "text-success", ring: "ring-success/20" },
};

const containerVariants = {
  hidden: { opacity: 0 },
  visible: { opacity: 1, transition: { staggerChildren: 0.06 } },
};

const itemVariants = {
  hidden: { opacity: 0, y: 12, scale: 0.98 },
  visible: { opacity: 1, y: 0, scale: 1, transition: { duration: 0.35, ease: [0.25, 0.46, 0.45, 0.94] as [number, number, number, number] } },
  exit: { opacity: 0, x: -20, scale: 0.95, transition: { duration: 0.2 } },
};

type FilterTab = "all" | "unread" | "read";

const Notifications = () => {
  const [notifications, setNotifications] = useState(initialNotifications);
  const [filter, setFilter] = useState<FilterTab>("all");
  const unreadCount = notifications.filter((n) => !n.read).length;

  const filtered = notifications.filter((n) => {
    if (filter === "unread") return !n.read;
    if (filter === "read") return n.read;
    return true;
  });

  const markAllRead = () => {
    setNotifications((prev) => prev.map((n) => ({ ...n, read: true })));
  };

  const toggleRead = (id: string) => {
    setNotifications((prev) =>
      prev.map((n) => (n.id === id ? { ...n, read: !n.read } : n))
    );
  };

  const dismiss = (id: string) => {
    setNotifications((prev) => prev.filter((n) => n.id !== id));
  };

  return (
    <motion.div initial={{ opacity: 0 }} animate={{ opacity: 1 }} transition={{ duration: 0.3 }}>
      <PageHeader title="Notifications" description={`You have ${unreadCount} unread notification${unreadCount !== 1 ? "s" : ""}`}>
        <Button variant="outline" size="sm" onClick={markAllRead} disabled={unreadCount === 0} className="gap-2 shadow-sm">
          <CheckCheck className="h-4 w-4" />
          Mark all read
        </Button>
      </PageHeader>

      {/* Filter tabs */}
      <Tabs value={filter} onValueChange={(v) => setFilter(v as FilterTab)} className="mb-6">
        <TabsList className="bg-muted/50 p-1">
          <TabsTrigger value="all" className="text-xs font-medium">
            All ({notifications.length})
          </TabsTrigger>
          <TabsTrigger value="unread" className="text-xs font-medium">
            Unread ({unreadCount})
          </TabsTrigger>
          <TabsTrigger value="read" className="text-xs font-medium">
            Read ({notifications.length - unreadCount})
          </TabsTrigger>
        </TabsList>
      </Tabs>

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
            <p className="text-xs text-muted-foreground/60 mt-1">You're all caught up!</p>
          </motion.div>
        ) : (
          <motion.div
            variants={containerVariants}
            initial="hidden"
            animate="visible"
            className="space-y-2.5 max-w-3xl"
          >
            {filtered.map((n) => {
              const Icon = n.icon;
              const config = typeConfig[n.type];
              return (
                <motion.div key={n.id} variants={itemVariants} exit={itemVariants.exit} layout>
                  <Card
                    className={`group relative overflow-hidden transition-all duration-200 hover:shadow-md ${
                      !n.read
                        ? "bg-card shadow-sm ring-1 ring-border"
                        : "bg-muted/20 shadow-none"
                    }`}
                  >
                    {/* Unread indicator bar */}
                    {!n.read && (
                      <div className="absolute left-0 top-0 bottom-0 w-1 bg-accent rounded-l-lg" />
                    )}

                    <CardContent className="flex items-start gap-4 py-4 pl-5 pr-4">
                      {/* Icon */}
                      <div className={`h-10 w-10 rounded-xl flex items-center justify-center shrink-0 ${config.bg} ring-1 ${config.ring}`}>
                        <Icon className={`h-[18px] w-[18px] ${config.text}`} />
                      </div>

                      {/* Content */}
                      <div className="flex-1 min-w-0">
                        <div className="flex items-center gap-2 mb-0.5">
                          <p className={`text-sm leading-tight ${!n.read ? "font-semibold text-foreground" : "font-medium text-muted-foreground"}`}>
                            {n.title}
                          </p>
                          {!n.read && (
                            <span className="h-2 w-2 rounded-full bg-accent shrink-0 animate-pulse" />
                          )}
                        </div>
                        <p className="text-xs text-muted-foreground/80 leading-relaxed line-clamp-2">{n.message}</p>
                        <div className="flex items-center gap-1 mt-2">
                          <Clock className="h-3 w-3 text-muted-foreground/50" />
                          <span className="text-[11px] text-muted-foreground/60 font-medium">{n.time}</span>
                        </div>
                      </div>

                      {/* Actions */}
                      <div className="flex items-center gap-1 shrink-0 md:opacity-0 md:group-hover:opacity-100 transition-opacity duration-200">
                        <Button
                          variant="ghost"
                          size="icon"
                          className="h-8 w-8 text-muted-foreground hover:text-foreground"
                          onClick={(e) => { e.stopPropagation(); toggleRead(n.id); }}
                          title={n.read ? "Mark unread" : "Mark read"}
                        >
                          <CheckCheck className="h-3.5 w-3.5" />
                        </Button>
                        <Button
                          variant="ghost"
                          size="icon"
                          className="h-8 w-8 text-muted-foreground hover:text-destructive"
                          onClick={(e) => { e.stopPropagation(); dismiss(n.id); }}
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
    </motion.div>
  );
};

export default Notifications;
