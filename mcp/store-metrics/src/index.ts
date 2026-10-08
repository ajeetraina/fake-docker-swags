#!/usr/bin/env node
// store-metrics MCP server.
//
// Exposes the conversion-signal tools the Swag Lab A/B agent calls to turn
// Browser-Use shopper traces into a verdict. Runs over stdio so it can be
// wired into a sandbox through the sbx MCP gateway.
//
// Tools:
//   score_trace       one trace  -> per-trace metrics
//   conversion_report a directory of traces -> aggregate signal
//   compare_variants  baseline dir vs variant dir -> lift + verdict
import { readdirSync, readFileSync } from "node:fs";
import { join } from "node:path";
import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import { z } from "zod";
import {
  aggregate,
  compare,
  scoreTrace,
  type ShopperTrace,
  type TraceMetrics,
} from "./metrics.js";

function loadTracesFromDir(dir: string): ShopperTrace[] {
  return readdirSync(dir)
    .filter((f) => f.endsWith(".json"))
    .map((f) => JSON.parse(readFileSync(join(dir, f), "utf8")) as ShopperTrace);
}

function ok(data: unknown) {
  return { content: [{ type: "text" as const, text: JSON.stringify(data, null, 2) }] };
}

const server = new McpServer({ name: "store-metrics", version: "0.1.0" });

server.tool(
  "score_trace",
  "Score a single Browser-Use shopper trace (JSON) into conversion metrics: " +
    "success, steps, whether the cart was reached, steps-to-cart, and friction signals.",
  { trace: z.string().describe("A shopper trace as a JSON string (output of `shop`).") },
  async ({ trace }) => ok(scoreTrace(JSON.parse(trace) as ShopperTrace)),
);

server.tool(
  "conversion_report",
  "Aggregate every *.json trace in a directory into one conversion report: " +
    "success rate, avg steps, avg steps-to-cart, abandonment rate, total friction.",
  { dir: z.string().describe("Directory containing shopper trace .json files.") },
  async ({ dir }) => {
    const metrics: TraceMetrics[] = loadTracesFromDir(dir).map(scoreTrace);
    return ok({ dir, perTask: metrics, aggregate: aggregate(metrics) });
  },
);

server.tool(
  "compare_variants",
  "Compare a variant's traces against the baseline's over the same tasks and " +
    "return the lift (success, steps-to-cart, abandonment, friction) and a verdict.",
  {
    baselineDir: z.string().describe("Directory of baseline shopper traces."),
    variantDir: z.string().describe("Directory of variant shopper traces."),
  },
  async ({ baselineDir, variantDir }) => {
    const baseline = aggregate(loadTracesFromDir(baselineDir).map(scoreTrace));
    const variant = aggregate(loadTracesFromDir(variantDir).map(scoreTrace));
    return ok(compare(baseline, variant));
  },
);

await server.connect(new StdioServerTransport());
console.error("[store-metrics] MCP server ready on stdio");
