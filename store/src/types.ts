export interface Product {
  id: string;
  name: string;
  category: string;
  price: number;
  tags: string[];
  emoji: string;
  description: string;
  inStock: boolean;
}

export interface CartLine {
  product: Product;
  qty: number;
}

export interface Review {
  author: string;
  rating: number;
  text: string;
}

export type Reviews = Record<string, Review[]>;
