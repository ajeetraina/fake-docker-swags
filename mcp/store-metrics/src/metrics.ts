// Conversion-signal metrics derived from Browser-Use shopper traces.
//
// A trace is what `shop "<goal>" <url>` emits: the shopper's goal, the ordered
// steps (each with the agent's reasoning and the action it took), and whether
// it declared success. We turn that into the three signals the A/B agent
// compares across variants.

export interface TraceStep {
  thought?: string | null;
  action?: string | null;
}

export interface ShopperTrace {
  task: string;
  url: string;
  steps: TraceStep[];
  final?: string | null;
  success?: boolean | null;
}

export interface TraceMetrics {
  task: string;
  success: boolean;
  steps: number;
  reachedCart: boolean;
  stepsToCart: number | null; // null if the cart was never reached
  frictionSignals: number; // count of steps that read as confusion / being stuck
}

const CART_RE = /add to cart|added to cart|added .* to .* cart|checkout/i;
const FRICTION_RE =
  /can.?t find|cannot find|couldn.?t find|no (filter|search|way to)|hard to|stuck|confus|overwhelm|too many|scroll(ing)? (through|past)|give up|gave up/i;

function stepText(s: TraceStep): string {
  return `${s.thought ?? ""} ${s.action ?? ""}`;
}

export function scoreTrace(trace: ShopperTrace): TraceMetrics {
  const steps = trace.steps ?? [];
  let stepsToCart: number | null = null;

  steps.forEach((s, i) => {
    if (stepsToCart === null && CART_RE.test(stepText(s))) {
      stepsToCart = i + 1;
    }
  });

  const frictionSignals = steps.filter((s) => FRICTION_RE.test(stepText(s))).length;
  const reachedCart = stepsToCart !== null;

  return {
    task: trace.task,
    // Trust an explicit success flag; otherwise infer it from reaching the cart.
    success: trace.success ?? reachedCart,
    steps: steps.length,
    reachedCart,
    stepsToCart,
    frictionSignals,
  };
}

export interface Aggregate {
  traces: number;
  successRate: number; // 0..1
  avgSteps: number;
  avgStepsToCart: number | null; // over traces that reached the cart
  abandonmentRate: number; // 0..1, shoppers who never reached the cart
  totalFrictionSignals: number;
}

export function aggregate(metrics: TraceMetrics[]): Aggregate {
  const n = metrics.length;
  if (n === 0) {
    return {
      traces: 0,
      successRate: 0,
      avgSteps: 0,
      avgStepsToCart: null,
      abandonmentRate: 0,
      totalFrictionSignals: 0,
    };
  }
  const successes = metrics.filter((m) => m.success).length;
  const carted = metrics.filter((m) => m.reachedCart);
  const avgStepsToCart =
    carted.length === 0
      ? null
      : carted.reduce((a, m) => a + (m.stepsToCart ?? 0), 0) / carted.length;

  return {
    traces: n,
    successRate: successes / n,
    avgSteps: metrics.reduce((a, m) => a + m.steps, 0) / n,
    avgStepsToCart,
    abandonmentRate: (n - carted.length) / n,
    totalFrictionSignals: metrics.reduce((a, m) => a + m.frictionSignals, 0),
  };
}

export interface Comparison {
  baseline: Aggregate;
  variant: Aggregate;
  lift: {
    successRate: number; // variant - baseline, in absolute points (0..1)
    avgStepsToCart: number | null; // negative is better (fewer steps)
    abandonmentRate: number; // negative is better
    frictionSignals: number; // negative is better
  };
  verdict: "variant wins" | "baseline wins" | "no clear difference";
}

export function compare(baseline: Aggregate, variant: Aggregate): Comparison {
  const successDelta = variant.successRate - baseline.successRate;
  const abandonDelta = variant.abandonmentRate - baseline.abandonmentRate;
  const frictionDelta = variant.totalFrictionSignals - baseline.totalFrictionSignals;
  const stepsDelta =
    baseline.avgStepsToCart === null || variant.avgStepsToCart === null
      ? null
      : variant.avgStepsToCart - baseline.avgStepsToCart;

  // A variant wins if it converts more shoppers or clearly removes friction
  // without regressing conversion.
  let verdict: Comparison["verdict"] = "no clear difference";
  if (successDelta > 0.05 || (abandonDelta < -0.05 && successDelta >= 0)) {
    verdict = "variant wins";
  } else if (successDelta < -0.05 || abandonDelta > 0.05) {
    verdict = "baseline wins";
  }

  return {
    baseline,
    variant,
    lift: {
      successRate: successDelta,
      avgStepsToCart: stepsDelta,
      abandonmentRate: abandonDelta,
      frictionSignals: frictionDelta,
    },
    verdict,
  };
}
