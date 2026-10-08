import { useCallback, useMemo, useState } from "react";
import type { CartLine, Product } from "./types";

export function useCart() {
  const [lines, setLines] = useState<CartLine[]>([]);

  const add = useCallback((product: Product) => {
    setLines((prev) => {
      const existing = prev.find((l) => l.product.id === product.id);
      if (existing) {
        return prev.map((l) =>
          l.product.id === product.id ? { ...l, qty: l.qty + 1 } : l,
        );
      }
      return [...prev, { product, qty: 1 }];
    });
  }, []);

  const remove = useCallback((id: string) => {
    setLines((prev) => prev.filter((l) => l.product.id !== id));
  }, []);

  const count = useMemo(
    () => lines.reduce((n, l) => n + l.qty, 0),
    [lines],
  );
  const total = useMemo(
    () => lines.reduce((n, l) => n + l.qty * l.product.price, 0),
    [lines],
  );

  return { lines, add, remove, count, total };
}
