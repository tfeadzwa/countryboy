import cboyLogo from "@/assets/cboy-logo.svg";

// CSS filter: converts all fills → CB Red hsl(2,72%,43%)
// Used when the logo appears on a light background (mobile / auth pages)
const cbRedFilter =
  "brightness(0) saturate(100%) invert(17%) sepia(83%) saturate(2600%) hue-rotate(347deg) brightness(92%)";

type BrandLogoProps = {
  /**
   * "light" — dark background (sidebar, login left panel).
   *   SVG uses its own built-in red + white fills.
   *
   * "dark"  — light background (auth pages on mobile, ForgotPassword, ResetPassword).
   *   CSS filter converts everything to CB Red so it reads against white.
   */
  variant?: "light" | "dark";

  /** Tailwind height class, e.g. "h-10", "h-12". Defaults to "h-10". */
  height?: string;

  /** Show "Admin Console" sub-label below the logo. */
  showSubtitle?: boolean;

  /** Override the sub-label text (default: "Admin Console"). */
  subtitle?: string;
};

const BrandLogo = ({
  variant = "light",
  height = "h-10",
  showSubtitle = false,
  subtitle = "Admin Console",
}: BrandLogoProps) => {
  return (
    <div className="inline-flex flex-col items-start gap-1">
      <img
        src={cboyLogo}
        alt="Country Boy"
        className={`${height} w-auto`}
        style={variant === "dark" ? { filter: cbRedFilter } : undefined}
      />
      {showSubtitle && (
        <p
          className={`text-[10px] font-semibold uppercase tracking-[0.2em] ${
            variant === "dark" ? "text-foreground/50" : "text-white/50"
          }`}
          style={{ fontFamily: "var(--font-display)" }}
        >
          {subtitle}
        </p>
      )}
    </div>
  );
};

export default BrandLogo;
