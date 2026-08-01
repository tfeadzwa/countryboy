/** Trip list ordering: active first, then completed by most recently ended. */

import type { Trip } from '@/types';

const toTime = (value?: string | null): number => {
  if (!value) return 0;
  const time = new Date(value).getTime();
  return Number.isNaN(time) ? 0 : time;
};

const sortRank = (status: string): number => {
  if (status === 'ACTIVE') return 0;
  if (status === 'ENDED' || status === 'COMPLETED') return 1;
  if (status === 'CANCELLED') return 2;
  return 3;
};

export function compareTrips(a: Trip, b: Trip): number {
  const rankDiff = sortRank(a.status) - sortRank(b.status);
  if (rankDiff !== 0) return rankDiff;

  if (a.status === 'ACTIVE') {
    return toTime(b.started_at) - toTime(a.started_at);
  }

  const endedDiff = toTime(b.ended_at) - toTime(a.ended_at);
  if (endedDiff !== 0) return endedDiff;

  return toTime(b.started_at) - toTime(a.started_at);
}

export function sortTrips(trips: Trip[]): Trip[] {
  return [...trips].sort(compareTrips);
}
