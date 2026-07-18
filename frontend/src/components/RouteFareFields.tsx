import { Plus, Trash2 } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { CURRENCY_OPTIONS } from "@/lib/constants/currencies";

export type FareDraft = {
  id?: string;
  currency: string;
  amount: string;
};

interface RouteFareFieldsProps {
  fares: FareDraft[];
  onChange: (fares: FareDraft[]) => void;
  disabled?: boolean;
  label?: string;
  description?: string;
  canRemove?: (fare: FareDraft) => boolean;
}

const emptyFare = (): FareDraft => ({ currency: "USD", amount: "" });

const RouteFareFields = ({
  fares,
  onChange,
  disabled = false,
  label = "Fares",
  description = "Set ticket prices for this route. Add one row per currency.",
  canRemove = () => true,
}: RouteFareFieldsProps) => {
  const updateFare = (index: number, patch: Partial<FareDraft>) => {
    onChange(fares.map((fare, i) => (i === index ? { ...fare, ...patch } : fare)));
  };

  const removeFare = (index: number) => {
    onChange(fares.filter((_, i) => i !== index));
  };

  const addFare = () => {
    const used = new Set(fares.map((f) => f.currency));
    const nextCurrency =
      CURRENCY_OPTIONS.find((c) => !used.has(c.value))?.value ?? "USD";
    onChange([...fares, { currency: nextCurrency, amount: "" }]);
  };

  return (
    <div className="space-y-3 rounded-lg border border-border/70 bg-muted/10 p-3">
      <div>
        <Label className="text-sm">{label}</Label>
        {description && (
          <p className="text-xs text-muted-foreground mt-0.5">{description}</p>
        )}
      </div>

      {fares.length === 0 ? (
        <p className="text-xs text-muted-foreground">No fares added yet.</p>
      ) : (
        <div className="space-y-2">
          {fares.map((fare, index) => (
            <div key={fare.id ?? `fare-${index}`} className="grid grid-cols-[1fr_1fr_auto] gap-2 items-end">
              <div className="space-y-1">
                {index === 0 && <Label className="text-xs text-muted-foreground">Currency</Label>}
                <Select
                  value={fare.currency}
                  onValueChange={(value) => updateFare(index, { currency: value })}
                  disabled={disabled}
                >
                  <SelectTrigger className="h-9">
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent>
                    {CURRENCY_OPTIONS.map((c) => (
                      <SelectItem key={c.value} value={c.value}>
                        {c.label}
                      </SelectItem>
                    ))}
                  </SelectContent>
                </Select>
              </div>
              <div className="space-y-1">
                {index === 0 && <Label className="text-xs text-muted-foreground">Amount</Label>}
                <Input
                  type="number"
                  step="0.01"
                  min="0"
                  placeholder="0.00"
                  value={fare.amount}
                  onChange={(e) => updateFare(index, { amount: e.target.value })}
                  disabled={disabled}
                  className="h-9"
                />
              </div>
              {canRemove(fare) ? (
                <Button
                  type="button"
                  variant="ghost"
                  size="icon"
                  className="h-9 w-9 shrink-0 text-muted-foreground hover:text-destructive"
                  onClick={() => removeFare(index)}
                  disabled={disabled}
                  aria-label="Remove fare"
                >
                  <Trash2 className="h-4 w-4" />
                </Button>
              ) : (
                <div className="h-9 w-9 shrink-0" aria-hidden />
              )}
            </div>
          ))}
        </div>
      )}

      <Button
        type="button"
        variant="outline"
        size="sm"
        className="gap-2"
        onClick={addFare}
        disabled={disabled}
      >
        <Plus className="h-4 w-4" />
        Add fare
      </Button>
    </div>
  );
};

export { emptyFare };
export default RouteFareFields;
