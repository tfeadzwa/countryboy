export const CURRENCY_OPTIONS = [
  { value: "USD", label: "USD ($)" },
  { value: "ZWL", label: "ZWL (Z$)" },
  { value: "ZAR", label: "ZAR (R)" },
] as const;

export type CurrencyCode = (typeof CURRENCY_OPTIONS)[number]["value"];
