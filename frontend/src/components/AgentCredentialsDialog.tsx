import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogDescription } from "@/components/ui/dialog";
import { Button } from "@/components/ui/button";
import { Copy, UserCheck, ShieldCheck, MessageSquare, KeyRound, Hash, Lock, CheckCircle2 } from "lucide-react";
import { useToast } from "@/hooks/use-toast";
import { Badge } from "@/components/ui/badge";
import { motion } from "framer-motion";

interface AgentCredentials {
  full_name: string;
  username: string;
  merchant_code: string;
  agent_code: string;
  pin: string;
  depot_name?: string;
}

interface AgentCredentialsDialogProps {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  credentials: AgentCredentials | null;
  isNewAgent?: boolean;
}

const credentialIcons: Record<string, React.ReactNode> = {
  "Merchant Code": <KeyRound className="h-4 w-4 text-primary" />,
  "Agent Code": <Hash className="h-4 w-4 text-accent" />,
  "PIN": <Lock className="h-4 w-4 text-warning" />,
};

const AgentCredentialsDialog = ({ open, onOpenChange, credentials, isNewAgent = false }: AgentCredentialsDialogProps) => {
  const { toast } = useToast();

  if (!credentials) return null;

  const copyToClipboard = (text: string, label: string) => {
    navigator.clipboard.writeText(text);
    toast({ title: "Copied!", description: `${label} copied to clipboard.` });
  };

  const copyAll = () => {
    const text = isNewAgent && credentials.pin
      ? `Agent: ${credentials.full_name}\nUsername: ${credentials.username}\nMerchant Code: ${credentials.merchant_code}\nAgent Code: ${credentials.agent_code}\nPIN: ${credentials.pin}\nDepot: ${credentials.depot_name || "N/A"}`
      : `Agent: ${credentials.full_name}\nUsername: ${credentials.username}\nMerchant Code: ${credentials.merchant_code}\nAgent Code: ${credentials.agent_code}\nDepot: ${credentials.depot_name || "N/A"}`;
    navigator.clipboard.writeText(text);
    toast({ title: "All credentials copied!", description: "You can now share them with the agent." });
  };

  // Only show PIN for newly created agents (plain text available)
  const items = [
    { label: "Merchant Code", value: credentials.merchant_code },
    { label: "Agent Code", value: credentials.agent_code },
    ...(isNewAgent && credentials.pin ? [{ label: "PIN", value: credentials.pin }] : []),
  ];

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="sm:max-w-2xl p-0 overflow-hidden gap-0">
        {/* Header with gradient accent */}
        <div className="relative bg-gradient-to-br from-primary/8 via-accent/5 to-transparent px-6 pt-6 pb-4">
          <div className="absolute top-0 right-0 w-32 h-32 bg-primary/5 rounded-full -translate-y-1/2 translate-x-1/2" />
          <DialogHeader className="relative z-10">
            <div className="flex items-center gap-3">
              <div className="flex h-10 w-10 items-center justify-center rounded-xl bg-primary/10 ring-1 ring-primary/20">
                {isNewAgent ? (
                  <ShieldCheck className="h-5 w-5 text-primary" />
                ) : (
                  <UserCheck className="h-5 w-5 text-primary" />
                )}
              </div>
              <div className="text-left">
                <DialogTitle className="text-base font-semibold font-heading">
                  {isNewAgent ? "Agent Created!" : "Agent Credentials"}
                </DialogTitle>
                <DialogDescription className="text-xs mt-0.5">
                  {isNewAgent
                    ? "Credentials generated successfully"
                    : `Viewing credentials for ${credentials.full_name}`}
                </DialogDescription>
              </div>
            </div>
          </DialogHeader>
        </div>

        <div className="px-6 pb-6 pt-4">
          <div className="grid sm:grid-cols-5 gap-4">
            {/* Left column — credentials (3/5) */}
            <div className="sm:col-span-3 space-y-3">
              {/* Agent identity bar */}
              <div className="flex items-center justify-between rounded-lg bg-muted/40 border border-border/60 px-3 py-2.5">
                <div className="flex items-center gap-2.5">
                  <div className="h-8 w-8 rounded-full bg-secondary/10 flex items-center justify-center text-xs font-bold text-secondary">
                    {credentials.full_name.split(" ").map(n => n[0]).join("")}
                  </div>
                  <div>
                    <p className="font-medium text-sm leading-tight">{credentials.full_name}</p>
                    <p className="text-[11px] text-muted-foreground font-mono">{credentials.username}</p>
                  </div>
                </div>
                {credentials.depot_name && (
                  <Badge variant="outline" className="text-[10px] font-medium bg-background">{credentials.depot_name}</Badge>
                )}
              </div>

              {/* Credential cards */}
              <div className="grid grid-cols-3 gap-2">
                {items.map((item, i) => (
                  <motion.div
                    key={item.label}
                    initial={{ opacity: 0, y: 8 }}
                    animate={{ opacity: 1, y: 0 }}
                    transition={{ delay: i * 0.08, duration: 0.25 }}
                    className="group relative rounded-xl border border-border/70 bg-card p-3 flex flex-col items-center gap-2 hover:border-primary/30 hover:shadow-sm transition-all duration-200"
                  >
                    <div className="flex items-center gap-1.5">
                      {credentialIcons[item.label]}
                      <p className="text-[10px] font-medium text-muted-foreground uppercase tracking-wider">{item.label}</p>
                    </div>
                    <p className="text-base font-bold font-mono tracking-[0.15em] text-foreground">{item.value}</p>
                    <Button
                      type="button"
                      variant="ghost"
                      size="sm"
                      className="h-6 text-[11px] gap-1 w-full hover:bg-primary/10 hover:text-primary rounded-md"
                      onClick={() => copyToClipboard(item.value, item.label)}
                    >
                      <Copy className="h-3 w-3" /> Copy
                    </Button>
                  </motion.div>
                ))}
              </div>

              {/* PIN Security Notice for existing agents */}
              {!isNewAgent && (
                <div className="rounded-lg border border-warning/20 bg-warning/5 px-3 py-2">
                  <div className="flex items-start gap-2">
                    <Lock className="h-3.5 w-3.5 text-warning mt-0.5 flex-shrink-0" />
                    <div className="text-[11px] text-muted-foreground">
                      <p className="font-medium text-warning">PIN Hidden for Security</p>
                      <p className="mt-0.5">PINs are encrypted and cannot be retrieved. Agent must remember their PIN or request a reset.</p>
                    </div>
                  </div>
                </div>
              )}

              {/* Copy all */}
              <Button
                variant="outline"
                size="sm"
                className="w-full gap-2 rounded-lg border-dashed hover:border-primary/40 hover:bg-primary/5 transition-colors"
                onClick={copyAll}
              >
                <Copy className="h-3.5 w-3.5" /> Copy All Credentials
              </Button>
            </div>

            {/* Right column — instructions (2/5) */}
            <div className="sm:col-span-2">
              <div className="rounded-xl border border-primary/15 bg-primary/[0.03] p-4 space-y-3 h-full">
                <div className="flex items-center gap-2">
                  <div className="h-6 w-6 rounded-md bg-primary/10 flex items-center justify-center">
                    <MessageSquare className="h-3.5 w-3.5 text-primary" />
                  </div>
                  <p className="text-xs font-semibold text-foreground">Sharing Guide</p>
                </div>
                <ol className="text-[11px] text-muted-foreground space-y-2.5">
                  {(isNewAgent ? [
                    <>Copy all credentials using the button.</>,
                    <>Send via a <strong className="text-foreground/80">secure channel</strong> (in-person or encrypted).</>,
                    <>Agent enters <strong className="text-foreground/80">Agent Code</strong> on device.</>,
                    <><strong className="text-foreground/80">PIN</strong> authorizes sales — keep private.</>,
                    <>This is the only time PIN is visible.</>,
                  ] : [
                    <>Copy agent code and merchant code.</>,
                    <>Share credentials with agent via secure method.</>,
                    <>Agent uses these to log into mobile app.</>,
                    <>PIN is encrypted and cannot be retrieved.</>,
                    <>If agent forgot PIN, you must reset it.</>,
                  ]).map((text, i) => (
                    <li key={i} className="flex gap-2 leading-relaxed">
                      <span className="flex-shrink-0 mt-0.5 h-4 w-4 rounded-full bg-primary/10 flex items-center justify-center text-[9px] font-bold text-primary">
                        {i + 1}
                      </span>
                      <span>{text}</span>
                    </li>
                  ))}
                </ol>
              </div>
            </div>
          </div>

          {/* Footer */}
          <div className="pt-4 mt-4 border-t border-border/50 flex items-center justify-between">
            {isNewAgent && (
              <div className="flex items-center gap-1.5 text-xs text-primary">
                <CheckCircle2 className="h-3.5 w-3.5" />
                <span className="font-medium">Agent ready for deployment</span>
              </div>
            )}
            <div className={isNewAgent ? "" : "ml-auto"}>
              <Button size="sm" className="rounded-lg px-5" onClick={() => onOpenChange(false)}>
                {isNewAgent ? "Done" : "Close"}
              </Button>
            </div>
          </div>
        </div>
      </DialogContent>
    </Dialog>
  );
};

export default AgentCredentialsDialog;
