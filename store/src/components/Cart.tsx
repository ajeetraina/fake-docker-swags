import type { CartLine } from "../types";

export function Cart({
  lines,
  total,
  onRemove,
}: {
  lines: CartLine[];
  total: number;
  onRemove: (id: string) => void;
}) {
  if (lines.length === 0) {
    return <p className="cart-empty">Your cart is empty.</p>;
  }
  return (
    <div className="cart">
      <ul className="cart-lines">
        {lines.map((l) => (
          <li key={l.product.id} className="cart-line">
            <span>
              {l.product.emoji} {l.product.name} × {l.qty}
            </span>
            <span>
              ${(l.product.price * l.qty).toFixed(2)}
              <button
                className="link"
                onClick={() => onRemove(l.product.id)}
                aria-label={`Remove ${l.product.name}`}
              >
                ✕
              </button>
            </span>
          </li>
        ))}
      </ul>
      <div className="cart-total">
        <strong>Total</strong>
        <strong>${total.toFixed(2)}</strong>
      </div>
      <button className="btn btn-checkout">Checkout</button>
    </div>
  );
}
