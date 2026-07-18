import { useEffect, useState } from "react";
import { useParams, Link } from "react-router-dom";
import { motion } from "framer-motion";
import {
  CheckCircle2,
  XCircle,
  Bus,
  MapPin,
  Calendar,
  User,
  BadgeCheck,
  Ticket,
  Phone,
  AlertTriangle,
  Loader2,
} from "lucide-react";
import BrandLogo from "@/components/BrandLogo";
import {
  publicTicketService,
  type TicketVerificationResult,
} from "@/lib/api/public-ticket.service";

const formatMoney = (currency: string, amount: number) =>
  `${currency} ${amount.toFixed(2)}`;

const formatDateTime = (iso: string) => {
  try {
    return new Intl.DateTimeFormat(undefined, {
      dateStyle: "medium",
      timeStyle: "short",
    }).format(new Date(iso));
  } catch {
    return iso;
  }
};

const VerifyTicket = () => {
  const { ticketId = "" } = useParams<{ ticketId: string }>();
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [data, setData] = useState<TicketVerificationResult | null>(null);

  useEffect(() => {
    let cancelled = false;

    const run = async () => {
      if (!ticketId.trim()) {
        setError("Missing ticket reference.");
        setLoading(false);
        return;
      }

      setLoading(true);
      setError(null);
      try {
        const result = await publicTicketService.verify(ticketId.trim());
        if (!cancelled) setData(result);
      } catch (err) {
        if (!cancelled) {
          setData(null);
          setError(
            err instanceof Error ? err.message : "Unable to verify this ticket.",
          );
        }
      } finally {
        if (!cancelled) setLoading(false);
      }
    };

    void run();
    return () => {
      cancelled = true;
    };
  }, [ticketId]);

  const isValid = data?.status === "VALID";

  return (
    <div className="relative min-h-screen overflow-hidden bg-[hsl(30_25%_97%)]">
      <div
        className="pointer-events-none absolute inset-0 opacity-90"
        style={{
          background:
            "radial-gradient(ellipse 80% 50% at 50% -10%, hsl(2 72% 43% / 0.18), transparent 55%), radial-gradient(ellipse 60% 40% at 100% 100%, hsl(38 82% 50% / 0.16), transparent 50%)",
        }}
      />
      <div
        className="pointer-events-none absolute inset-0 opacity-[0.035]"
        style={{
          backgroundImage:
            "url(\"data:image/svg+xml,%3Csvg width='60' height='60' viewBox='0 0 60 60' xmlns='http://www.w3.org/2000/svg'%3E%3Cg fill='none' fill-rule='evenodd'%3E%3Cg fill='%23181C22' fill-opacity='1'%3E%3Cpath d='M36 34v-4h-2v4h-4v2h4v4h2v-4h4v-2h-4zm0-30V0h-2v4h-4v2h4v4h2V6h4V4h-4zM6 34v-4H4v4H0v2h4v4h2v-4h4v-2H6zM6 4V0H4v4H0v2h4v4h2V6h4V4H6z'/%3E%3C/g%3E%3C/g%3E%3C/svg%3E\")",
        }}
      />

      <div className="relative z-10 mx-auto flex min-h-screen w-full max-w-lg flex-col px-4 py-8 sm:px-6">
        <motion.header
          initial={{ opacity: 0, y: -10 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.45 }}
          className="mb-8 flex flex-col items-center gap-2 text-center"
        >
          <BrandLogo variant="dark" height="h-12" />
          <p
            className="text-xs font-semibold uppercase tracking-[0.22em] text-muted-foreground"
            style={{ fontFamily: "var(--font-display)" }}
          >
            Ticket verification
          </p>
        </motion.header>

        <motion.main
          initial={{ opacity: 0, y: 18 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.5, delay: 0.08 }}
          className="flex-1"
        >
          {loading && (
            <div className="flex flex-col items-center justify-center gap-3 rounded-2xl border border-border/70 bg-white/80 px-6 py-16 shadow-sm backdrop-blur">
              <Loader2 className="h-8 w-8 animate-spin text-primary" />
              <p className="text-sm text-muted-foreground">
                Checking ticket authenticity…
              </p>
            </div>
          )}

          {!loading && error && (
            <div className="rounded-2xl border border-destructive/20 bg-white px-6 py-10 text-center shadow-sm">
              <div className="mx-auto mb-4 flex h-14 w-14 items-center justify-center rounded-full bg-destructive/10">
                <XCircle className="h-8 w-8 text-destructive" />
              </div>
              <h1
                className="text-2xl font-bold tracking-tight"
                style={{ fontFamily: "var(--font-display)" }}
              >
                Ticket not verified
              </h1>
              <p className="mt-2 text-sm text-muted-foreground">{error}</p>
              <p className="mt-4 text-xs text-muted-foreground">
                Scan the QR code printed on a Countryboy ticket, or ask the
                conductor for a valid receipt.
              </p>
            </div>
          )}

          {!loading && data?.ticket && (
            <div className="overflow-hidden rounded-2xl border border-border/70 bg-white shadow-[0_20px_50px_-28px_rgba(24,28,34,0.45)]">
              <div
                className={`px-6 py-5 text-white ${
                  isValid
                    ? "bg-gradient-to-br from-[hsl(142_55%_34%)] to-[hsl(142_45%_28%)]"
                    : "bg-gradient-to-br from-destructive to-[hsl(0_72%_42%)]"
                }`}
              >
                <div className="flex items-start gap-3">
                  {isValid ? (
                    <CheckCircle2 className="mt-0.5 h-7 w-7 shrink-0" />
                  ) : (
                    <AlertTriangle className="mt-0.5 h-7 w-7 shrink-0" />
                  )}
                  <div>
                    <p className="text-xs font-semibold uppercase tracking-[0.18em] text-white/80">
                      {isValid ? "Authentic ticket" : "Voided ticket"}
                    </p>
                    <h1
                      className="mt-1 text-2xl font-bold leading-tight"
                      style={{ fontFamily: "var(--font-display)" }}
                    >
                      {isValid
                        ? "This ticket was issued by Countryboy"
                        : "This ticket has been voided"}
                    </h1>
                    <p className="mt-1 text-sm text-white/85">
                      {data.ticket?.display_number ?? "—"} ·{" "}
                      {data.ticket?.category_label ?? "Ticket"}
                    </p>
                  </div>
                </div>
              </div>

              <div className="space-y-5 px-6 py-6">
                <div className="rounded-xl border border-border bg-[hsl(30_25%_97%)] px-4 py-4 text-center">
                  <p className="text-[11px] font-semibold uppercase tracking-[0.16em] text-muted-foreground">
                    Fare
                  </p>
                  <p
                    className="mt-1 text-3xl font-bold text-primary"
                    style={{ fontFamily: "var(--font-display)" }}
                  >
                    {formatMoney(data.ticket.currency, data.ticket.amount)}
                  </p>
                </div>

                {(data.ticket.origin || data.ticket.destination) && (
                  <div className="rounded-xl border border-border px-4 py-4">
                    <div className="mb-3 flex items-center gap-2 text-[11px] font-semibold uppercase tracking-[0.16em] text-muted-foreground">
                      <MapPin className="h-3.5 w-3.5" />
                      Route
                    </div>
                    <div className="flex flex-col items-center gap-1 text-center">
                      <p
                        className="text-lg font-semibold"
                        style={{ fontFamily: "var(--font-display)" }}
                      >
                        {data.ticket.origin ?? "—"}
                      </p>
                      <p className="text-xs uppercase tracking-widest text-muted-foreground">
                        to
                      </p>
                      <p
                        className="text-lg font-semibold"
                        style={{ fontFamily: "var(--font-display)" }}
                      >
                        {data.ticket.destination ?? "—"}
                      </p>
                    </div>
                  </div>
                )}

                <dl className="grid gap-3">
                  <Detail
                    icon={Ticket}
                    label="Ticket number"
                    value={data.ticket.display_number}
                  />
                  <Detail
                    icon={BadgeCheck}
                    label="Type"
                    value={data.ticket.category_label}
                  />
                  <Detail
                    icon={Bus}
                    label="Bus"
                    value={data.trip?.fleet_number ?? "—"}
                  />
                  <Detail
                    icon={Calendar}
                    label="Issued"
                    value={formatDateTime(data.ticket.issued_at)}
                  />
                  <Detail
                    icon={MapPin}
                    label="Depot"
                    value={data.depot?.name ?? "—"}
                  />
                  <Detail
                    icon={User}
                    label="Conductor"
                    value={data.conductor?.name ?? "—"}
                  />
                  {data.ticket.passenger_phone && (
                    <Detail
                      icon={Phone}
                      label="Phone"
                      value={data.ticket.passenger_phone}
                    />
                  )}
                </dl>

                {data.void_info && (
                  <div className="rounded-xl border border-destructive/25 bg-destructive/5 px-4 py-3 text-sm">
                    <p className="font-semibold text-destructive">Void reason</p>
                    <p className="mt-1 text-foreground/80">{data.void_info.reason}</p>
                    <p className="mt-1 text-xs text-muted-foreground">
                      Voided {formatDateTime(data.void_info.voided_at)}
                    </p>
                  </div>
                )}

                <div className="flex items-center gap-2 rounded-xl bg-[hsl(142_55%_38%/0.08)] px-4 py-3 text-sm text-[hsl(142_55%_28%)]">
                  <BadgeCheck className="h-4 w-4 shrink-0" />
                  <span>
                    Verification ID matches an issued Countryboy ticket record.
                  </span>
                </div>
              </div>
            </div>
          )}
        </motion.main>

        <footer className="mt-8 text-center text-xs text-muted-foreground">
          <p>Countryboy Transport · Official ticket check</p>
          <Link to="/login" className="mt-1 inline-block text-primary hover:underline">
            Staff login
          </Link>
        </footer>
      </div>
    </div>
  );
};

function Detail({
  icon: Icon,
  label,
  value,
}: {
  icon: typeof Ticket;
  label: string;
  value: string;
}) {
  return (
    <div className="flex items-start gap-3 rounded-lg border border-transparent px-1 py-1.5">
      <div className="mt-0.5 flex h-8 w-8 shrink-0 items-center justify-center rounded-lg bg-muted">
        <Icon className="h-4 w-4 text-muted-foreground" />
      </div>
      <div className="min-w-0">
        <dt className="text-[11px] font-medium uppercase tracking-wide text-muted-foreground">
          {label}
        </dt>
        <dd className="truncate text-sm font-medium text-foreground">{value}</dd>
      </div>
    </div>
  );
}

export default VerifyTicket;
