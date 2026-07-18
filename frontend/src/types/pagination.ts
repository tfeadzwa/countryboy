export interface PaginatedResult<T> {
  items: T[];
  total: number;
  page: number;
  pageSize: number;
  totalPages: number;
}

export const DEFAULT_PAGE_SIZE = 10;

/** Accept either a paginated payload or a legacy plain array. */
export function normalizePaginatedResult<T>(
  data: PaginatedResult<T> | T[] | null | undefined,
  page = 1,
  pageSize = DEFAULT_PAGE_SIZE,
): PaginatedResult<T> {
  if (Array.isArray(data)) {
    return {
      items: data,
      total: data.length,
      page,
      pageSize,
      totalPages: Math.max(1, Math.ceil(data.length / pageSize) || 1),
    };
  }

  const items = Array.isArray(data?.items) ? data.items : [];
  const total = typeof data?.total === "number" ? data.total : items.length;
  const resolvedPage = typeof data?.page === "number" ? data.page : page;
  const resolvedPageSize = typeof data?.pageSize === "number" ? data.pageSize : pageSize;
  const totalPages =
    typeof data?.totalPages === "number"
      ? data.totalPages
      : Math.max(1, Math.ceil(total / resolvedPageSize) || 1);

  return {
    items,
    total,
    page: resolvedPage,
    pageSize: resolvedPageSize,
    totalPages,
  };
}
