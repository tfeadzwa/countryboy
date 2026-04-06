import { Alert, AlertDescription, AlertTitle } from "@/components/ui/alert";
import { AlertCircle } from "lucide-react";

interface ErrorAlertProps {
  error: string | null;
  title?: string;
  className?: string;
}

/**
 * Reusable error alert component for consistent error display across the application
 */
const ErrorAlert = ({ error, title = "Error", className = "mb-6" }: ErrorAlertProps) => {
  if (!error) return null;

  return (
    <Alert variant="destructive" className={className}>
      <AlertCircle className="h-4 w-4" />
      {title && <AlertTitle>{title}</AlertTitle>}
      <AlertDescription>{error}</AlertDescription>
    </Alert>
  );
};

export default ErrorAlert;
