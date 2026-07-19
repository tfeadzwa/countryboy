import { Copy, Key } from "lucide-react";
import { Button } from "@/components/ui/button";
import { cn } from "@/lib/utils";

interface PairingCodeDisplayProps {
  code: string;
  onCopy?: () => void;
  className?: string;
  hint?: string;
}

/** Large, easy-to-read pairing code block for register / device details. */
const PairingCodeDisplay = ({
  code,
  onCopy,
  className,
  hint = "Enter this code in the mobile app to pair the device",
}: PairingCodeDisplayProps) => {
  const chars = code.replace(/[^A-Za-z0-9]/g, "").toUpperCase().split("");

  return (
    <div
      className={cn(
        "rounded-2xl border border-primary/20 bg-gradient-to-b from-primary/[0.07] to-background p-4 sm:p-5",
        className,
      )}
    >
      <div className="flex items-center justify-between gap-3 mb-3">
        <div className="flex items-center gap-2">
          <div className="flex h-8 w-8 items-center justify-center rounded-lg bg-primary/10">
            <Key className="h-4 w-4 text-primary" />
          </div>
          <div>
            <p className="text-sm font-semibold leading-none">Pairing code</p>
            {hint && (
              <p className="text-[11px] text-muted-foreground mt-1 leading-snug">{hint}</p>
            )}
          </div>
        </div>
        {onCopy && (
          <Button
            type="button"
            variant="outline"
            size="sm"
            className="gap-1.5 shrink-0"
            onClick={onCopy}
          >
            <Copy className="h-3.5 w-3.5" />
            Copy
          </Button>
        )}
      </div>

      <div className="flex justify-center gap-1.5 sm:gap-2 py-1">
        {chars.map((char, index) => (
          <div key={`${char}-${index}`} className="flex items-center gap-1.5 sm:gap-2">
            {index === 3 && chars.length >= 6 && (
              <span className="text-muted-foreground/70 font-semibold px-0.5 select-none">·</span>
            )}
            <div
              className={cn(
                "flex h-11 w-9 sm:h-12 sm:w-10 items-center justify-center rounded-xl",
                "border border-border/80 bg-background shadow-sm",
                "font-mono text-lg sm:text-xl font-bold tracking-wide text-foreground",
              )}
            >
              {char}
            </div>
          </div>
        ))}
      </div>
    </div>
  );
};

export default PairingCodeDisplay;
