import { describe, expect, it } from "vitest";
import { handler } from "./health.js";

describe("health", () => {
  it("returns 200 with ok: true", async () => {
    const res = await handler();
    expect(res).toMatchObject({ statusCode: 200 });
    expect(JSON.parse((res as { body: string }).body)).toEqual({ ok: true, service: "simmer-api" });
  });
});
