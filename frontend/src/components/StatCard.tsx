import { motion } from "framer-motion";
import { LucideIcon, ArrowUpRight, ArrowDownRight } from "lucide-react";

interface StatCardProps {
  label: string;
  value: string | number;
  icon: LucideIcon;
  variant: "blue" | "teal" | "amber" | "green";
  subtitle?: string;
  trend?: { value: number; label: string };
}

const variantStyles = {
  blue: {
    bg: "bg-card",
    iconBg: "bg-secondary/10",
    iconColor: "text-secondary",
    accentBorder: "border-l-secondary",
  },
  teal: {
    bg: "bg-card",
    iconBg: "bg-primary/10",
    iconColor: "text-primary",
    accentBorder: "border-l-primary",
  },
  amber: {
    bg: "bg-card",
    iconBg: "bg-accent/10",
    iconColor: "text-accent",
    accentBorder: "border-l-accent",
  },
  green: {
    bg: "bg-card",
    iconBg: "bg-success/10",
    iconColor: "text-success",
    accentBorder: "border-l-success",
  },
};

const StatCard = ({ label, value, icon: Icon, variant, subtitle, trend }: StatCardProps) => {
  const styles = variantStyles[variant];
  const isPositive = trend ? trend.value >= 0 : true;

  return (
    <motion.div
      initial={{ opacity: 0, y: 16 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.4, ease: [0.25, 0.46, 0.45, 0.94] }}
      className={`${styles.bg} rounded-xl p-5 border border-border/60 shadow-sm hover:shadow-md transition-shadow duration-200 border-l-[3px] ${styles.accentBorder} relative overflow-hidden`}
    >
      <div className="flex items-start justify-between mb-3">
        <div className={`h-10 w-10 rounded-lg ${styles.iconBg} flex items-center justify-center`}>
          <Icon className={`h-5 w-5 ${styles.iconColor}`} />
        </div>
        {trend && (
          <div className={`flex items-center gap-1 text-[11px] font-semibold px-2 py-0.5 rounded-full ${
            isPositive 
              ? "bg-success/10 text-success" 
              : "bg-destructive/10 text-destructive"
          }`}>
            {isPositive ? <ArrowUpRight className="h-3 w-3" /> : <ArrowDownRight className="h-3 w-3" />}
            {Math.abs(trend.value)}%
          </div>
        )}
      </div>
      <p className="text-[11px] font-medium uppercase tracking-wider text-muted-foreground mb-1">{label}</p>
      <p className="text-2xl font-display font-bold text-foreground tracking-tight">{value}</p>
      {subtitle && <p className="text-[11px] text-muted-foreground mt-1.5 font-medium">{subtitle}</p>}
    </motion.div>
  );
};

export default StatCard;
