import { reconcile } from '@northlake/reconcile-engine';
export const settle = (entries) => reconcile(entries);
