import type { Product } from "../types";
import { ProductCard } from "./ProductCard";

export function ProductGrid({
  products,
  onAdd,
}: {
  products: Product[];
  onAdd: (p: Product) => void;
}) {
  return (
    <section className="grid" aria-label="Products">
      {products.map((p) => (
        <ProductCard key={p.id} product={p} onAdd={onAdd} />
      ))}
    </section>
  );
}
