import { useState } from "react";
import rawProducts from "./data/products.json";
import type { Product } from "./types";
import { ProductGrid } from "./components/ProductGrid";
import { Cart } from "./components/Cart";
import { useCart } from "./useCart";

const products = rawProducts as Product[];

export function App() {
  const cart = useCart();
  const [cartOpen, setCartOpen] = useState(false);

  // ──────────────────────────────────────────────────────────────────────
  // DELIBERATE FLAW — the thing the Swag Lab agent is meant to discover.
  //
  // There are 12 products across 5 categories (Apparel, Toys, Stickers,
  // Drinkware, Office), but the storefront renders ALL of them as one flat
  // grid. There is no search box and no category filter. A shopper who wants
  // "a hoodie" has to eyeball the whole list.
  //
  // A browser-use agent asked to "find something to keep warm" will visibly
  // struggle here — that friction is the signal the analysis phase picks up,
  // and "add product filtering/search" is the variant the coding agent
  // implements. Do not add filtering here by hand; that is the agent's job.
  // ──────────────────────────────────────────────────────────────────────
  const visibleProducts = products;

  return (
    <div className="app">
      <header className="header">
        <div className="brand">
          <span className="brand-mark" aria-hidden>
            🐳
          </span>
          <span>Docker Swag Store</span>
        </div>
        <button className="cart-btn" onClick={() => setCartOpen((o) => !o)}>
          🛒 Cart ({cart.count})
        </button>
      </header>

      <main className="main">
        <div className="hero">
          <h1>Deck out your dev setup.</h1>
          <p>Official-ish Docker swag for whales of all sizes.</p>
        </div>

        {cartOpen && (
          <aside className="cart-panel">
            <h2>Your cart</h2>
            <Cart lines={cart.lines} total={cart.total} onRemove={cart.remove} />
          </aside>
        )}

        <ProductGrid products={visibleProducts} onAdd={cart.add} />
      </main>

      <footer className="footer">
        <span>{products.length} products · fake-docker-swags demo store</span>
      </footer>
    </div>
  );
}
