import type { APIGatewayProxyResultV2 } from "aws-lambda";

// GET /health — unauthenticated liveness check for the deploy pipeline.
export async function handler(): Promise<APIGatewayProxyResultV2> {
  return {
    statusCode: 200,
    headers: { "content-type": "application/json" },
    body: JSON.stringify({ ok: true, service: "simmer-api" }),
  };
}
