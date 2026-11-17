import {
  ExecutionContext,
  HttpException,
  ServiceUnavailableException,
} from "@nestjs/common";
import { ClerkTrialRateGuard } from "./clerk-identity.controller";
import { ClerkSessionPolicy } from "./clerk-session-policy.service";

describe("Clerk trial bounded request guard", () => {
  const context = (ip: string) =>
    ({
      switchToHttp: () => ({ getRequest: () => ({ ip }) }),
    }) as ExecutionContext;
  const create = () => {
    const config = { assertConfigured: jest.fn() };
    return {
      config,
      guard: new ClerkTrialRateGuard(config as unknown as ClerkSessionPolicy),
    };
  };
  it("blocks disabled configuration before any trial work", () => {
    const { config, guard } = create();
    config.assertConfigured.mockImplementation(() => {
      throw new ServiceUnavailableException();
    });
    expect(() => guard.canActivate(context("fixture"))).toThrow(
      ServiceUnavailableException,
    );
  });
  it("allows ten attempts per IP, rejects the next, and does not block another IP", () => {
    const { guard } = create();
    for (let i = 0; i < 10; i++)
      expect(guard.canActivate(context("fixture"))).toBe(true);
    expect(() => guard.canActivate(context("fixture"))).toThrow(HttpException);
    expect(guard.canActivate(context("other"))).toBe(true);
  });
  it("clears expired entries and bounds the number of distinct IPs", () => {
    jest.useFakeTimers();
    try {
      const { guard } = create();
      for (let i = 0; i < 1000; i++) guard.canActivate(context("fixture-" + i));
      expect(() => guard.canActivate(context("overflow"))).toThrow(
        HttpException,
      );
      jest.advanceTimersByTime(60001);
      expect(guard.canActivate(context("overflow"))).toBe(true);
    } finally {
      jest.useRealTimers();
    }
  });
});
