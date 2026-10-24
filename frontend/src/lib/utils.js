import { clsx } from 'clsx';
import { twMerge } from 'tailwind-merge';

/** Merge Tailwind classes with shadcn/cva compatibility */
export function cn(...inputs) {
  return twMerge(clsx(inputs));
}