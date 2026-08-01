import { useEffect, useState } from "react";
import { Link, useParams } from "react-router-dom";
import { motion } from "framer-motion";
import {
  ArrowLeft,
  Loader2,
  Monitor,
  Package,
  Smartphone,
  Star,
} from "lucide-react";
import PageHeader from "@/components/PageHeader";
import ErrorAlert from "@/components/ErrorAlert";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import {
  appReleaseService,
  getAdminNotes,
  getMobileNotes,
  hasReleaseNotes,
  type AppRelease,
} from "@/lib/api/app-release.service";

const formatDate = (iso: string) => {
  const d = new Date(iso);
  if (Number.isNaN(d.getTime())) return "—";
  return d.toLocaleString(undefined, {
    day: "numeric",
    month: "short",
    year: "numeric",
    hour: "2-digit",
    minute: "2-digit",
  });
};

const NotesSection = ({
  title,
  icon: Icon,
  text,
}: {
  title: string;
  icon: typeof Smartphone;
  text: string;
}) => (
  <Card className="shadow-sm border-border/60">
    <CardHeader className="pb-3">
      <div className="flex items-center gap-2">
        <Icon className="h-4 w-4 text-primary" />
        <CardTitle className="text-base font-display">{title}</CardTitle>
      </div>
      <CardDescription>
        {title === "Mobile app"
          ? "Changes shipped in the conductor Android build"
          : "Changes shipped on the admin web panel"}
      </CardDescription>
    </CardHeader>
    <CardContent>
      {text ? (
        <div className="rounded-xl border border-border/50 bg-muted/10 px-4 py-4">
          <p className="text-sm leading-relaxed whitespace-pre-wrap text-foreground/90">{text}</p>
        </div>
      ) : (
        <p className="text-sm text-muted-foreground italic">No notes recorded for this platform.</p>
      )}
    </CardContent>
  </Card>
);

const AppReleaseNotesPage = () => {
  const { id } = useParams<{ id: string }>();
  const [release, setRelease] = useState<AppRelease | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    if (!id) {
      setError("Missing release id");
      setLoading(false);
      return;
    }

    let cancelled = false;
    (async () => {
      setLoading(true);
      setError(null);
      try {
        const data = await appReleaseService.getById(id);
        if (!cancelled) setRelease(data);
      } catch (err) {
        if (!cancelled) {
          setError(err instanceof Error ? err.message : "Failed to load release notes");
        }
      } finally {
        if (!cancelled) setLoading(false);
      }
    })();

    return () => {
      cancelled = true;
    };
  }, [id]);

  return (
    <motion.div
      initial={{ opacity: 0 }}
      animate={{ opacity: 1 }}
      transition={{ duration: 0.3 }}
      className="space-y-6 pb-10"
    >
      <div className="flex flex-wrap items-center gap-3">
        <Button asChild variant="ghost" size="sm" className="gap-1.5 -ml-2">
          <Link to="/app-releases">
            <ArrowLeft className="h-4 w-4" />
            Back to App Releases
          </Link>
        </Button>
      </div>

      <PageHeader
        title={release ? `v${release.version_name} changelog` : "Release changelog"}
        description={
          release
            ? `Full change notes for build ${release.version_code}`
            : "Mobile and admin panel updates for this release"
        }
      />

      <ErrorAlert error={error} />

      {loading ? (
        <div className="flex items-center justify-center py-20 text-muted-foreground">
          <Loader2 className="mr-2 h-5 w-5 animate-spin" />
          Loading notes…
        </div>
      ) : release ? (
        <>
          <Card className="shadow-sm border-border/60">
            <CardContent className="flex flex-wrap items-center gap-3 py-4">
              <div className="flex h-10 w-10 items-center justify-center rounded-xl bg-primary/10">
                <Package className="h-5 w-5 text-primary" />
              </div>
              <div className="min-w-0 flex-1">
                <div className="flex flex-wrap items-center gap-2">
                  <p className="font-medium">v{release.version_name}</p>
                  <span className="text-xs text-muted-foreground">build {release.version_code}</span>
                  {release.is_current && (
                    <Badge
                      variant="outline"
                      className="text-[10px] gap-1 border-success/30 text-success"
                    >
                      <Star className="h-2.5 w-2.5" />
                      Current
                    </Badge>
                  )}
                </div>
                <p className="text-xs text-muted-foreground mt-0.5">
                  Published {formatDate(release.created_at)}
                  {release.updated_at !== release.created_at
                    ? ` · Updated ${formatDate(release.updated_at)}`
                    : ""}
                </p>
              </div>
            </CardContent>
          </Card>

          {!hasReleaseNotes(release) ? (
            <div className="rounded-xl border border-dashed border-border/70 bg-muted/15 px-4 py-12 text-center">
              <p className="text-sm text-muted-foreground">
                No changelog notes were published for this version.
              </p>
            </div>
          ) : (
            <div className="grid gap-5 lg:grid-cols-2">
              <NotesSection
                title="Mobile app"
                icon={Smartphone}
                text={getMobileNotes(release)}
              />
              <NotesSection
                title="Admin panel"
                icon={Monitor}
                text={getAdminNotes(release)}
              />
            </div>
          )}
        </>
      ) : null}
    </motion.div>
  );
};

export default AppReleaseNotesPage;
