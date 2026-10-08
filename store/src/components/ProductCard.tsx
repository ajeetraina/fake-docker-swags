import type { Product } from "../types";

export function ProductCard({
  product,
  onAdd,
  onSelect,
}: {
  product: Product;
  onAdd: (p: Product) => void;
  onSelect: (p: Product) => void;
}) {
  return (
    <article className="card" data-product-id={product.id} data-category={product.category}>
      <button className="card-open" onClick={() => onSelect(product)}>
        <div className="card-emoji" aria-hidden>
          {product.emoji}
        </div>
        <h3 className="card-name">{product.name}</h3>
        <p className="card-desc">{product.description}</p>
      </button>
      <div className="card-footer">
        <span className="card-price">${product.price.toFixed(2)}</span>
        <button
          className="btn"
          disabled={!product.inStock}
          onClick={() => onAdd(product)}
        >
          {product.inStock ? "Add to cart" : "Sold out"}
        </button>
      </div>
    </article>
  );
}
