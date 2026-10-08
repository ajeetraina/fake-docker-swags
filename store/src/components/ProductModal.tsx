import type { Product, Review } from "../types";

export function ProductModal({
  product,
  reviews,
  onAdd,
  onClose,
}: {
  product: Product;
  reviews: Review[];
  onAdd: (p: Product) => void;
  onClose: () => void;
}) {
  return (
    <div className="modal-backdrop" onClick={onClose}>
      <div
        className="modal"
        role="dialog"
        aria-label={product.name}
        onClick={(e) => e.stopPropagation()}
      >
        <button className="modal-close" onClick={onClose} aria-label="Close">
          ✕
        </button>
        <div className="modal-emoji" aria-hidden>
          {product.emoji}
        </div>
        <h2 className="modal-name">{product.name}</h2>
        <p className="modal-cat">{product.category}</p>
        <p className="modal-desc">{product.description}</p>
        <div className="modal-buy">
          <span className="card-price">${product.price.toFixed(2)}</span>
          <button className="btn" disabled={!product.inStock} onClick={() => onAdd(product)}>
            {product.inStock ? "Add to cart" : "Sold out"}
          </button>
        </div>

        <h3 className="modal-reviews-h">
          Reviews {reviews.length > 0 && <span>({reviews.length})</span>}
        </h3>
        {reviews.length === 0 ? (
          <p className="cart-empty">No reviews yet.</p>
        ) : (
          <ul className="reviews">
            {reviews.map((r, i) => (
              <li key={i} className="review">
                <div className="review-head">
                  <span className="review-author">{r.author}</span>
                  <span className="review-stars" aria-label={`${r.rating} stars`}>
                    {"★".repeat(r.rating)}
                    {"☆".repeat(Math.max(0, 5 - r.rating))}
                  </span>
                </div>
                <p className="review-text">{r.text}</p>
              </li>
            ))}
          </ul>
        )}
      </div>
    </div>
  );
}
