import { ReactNode } from "react";
import { motion } from "framer-motion";
import { useIsMobile } from "@/hooks/use-mobile";
import { Card, CardContent } from "@/components/ui/card";
import { Table, TableBody, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import { Inbox } from "lucide-react";

interface Column {
  header: string;
  className?: string;
}

interface ResponsiveTableProps<T> {
  columns: Column[];
  data: T[];
  renderRow: (item: T) => ReactNode;
  renderCard: (item: T) => ReactNode;
  keyExtractor: (item: T) => string;
  rowClassName?: (item: T) => string;
}

const cardVariants = {
  hidden: { opacity: 0, y: 8 },
  visible: (i: number) => ({
    opacity: 1,
    y: 0,
    transition: { duration: 0.3, delay: i * 0.04, ease: [0.25, 0.46, 0.45, 0.94] as [number, number, number, number] },
  }),
};

const EmptyState = () => (
  <div className="flex flex-col items-center justify-center py-16 text-center">
    <div className="h-12 w-12 rounded-xl bg-muted/60 flex items-center justify-center mb-3">
      <Inbox className="h-6 w-6 text-muted-foreground/60" />
    </div>
    <p className="text-sm font-medium text-muted-foreground">No data found</p>
    <p className="text-xs text-muted-foreground/60 mt-0.5">Try adjusting your filters</p>
  </div>
);

export function ResponsiveTable<T>({
  columns,
  data,
  renderRow,
  renderCard,
  keyExtractor,
}: ResponsiveTableProps<T>) {
  const isMobile = useIsMobile();

  if (isMobile) {
    return (
      <div className="space-y-3">
        {data.map((item, i) => (
          <motion.div
            key={keyExtractor(item)}
            custom={i}
            variants={cardVariants}
            initial="hidden"
            animate="visible"
          >
            <Card className="shadow-sm border-border/60 hover:shadow-md transition-shadow">
              <CardContent className="p-4">
                {renderCard(item)}
              </CardContent>
            </Card>
          </motion.div>
        ))}
        {data.length === 0 && <EmptyState />}
      </div>
    );
  }

  return (
    <motion.div
      initial={{ opacity: 0, y: 8 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.35, ease: [0.25, 0.46, 0.45, 0.94] }}
    >
      <Card className="shadow-sm border-border/60 overflow-hidden">
        <CardContent className="p-0">
          {data.length === 0 ? (
            <EmptyState />
          ) : (
            <Table>
              <TableHeader>
                <TableRow className="bg-muted/30 hover:bg-muted/30">
                  {columns.map((col) => (
                    <TableHead key={col.header} className={`text-xs font-semibold text-muted-foreground uppercase tracking-wider ${col.className ?? ""}`}>
                      {col.header}
                    </TableHead>
                  ))}
                </TableRow>
              </TableHeader>
              <TableBody>
                {data.map((item) => renderRow(item))}
              </TableBody>
            </Table>
          )}
        </CardContent>
      </Card>
    </motion.div>
  );
}
