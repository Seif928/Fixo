import {
  ServiceUnavailableException,
  UnauthorizedException,
} from "@nestjs/common";
import { ClerkSessionPolicy } from "./clerk-session-policy.service";

describe("Live Clerk session policy", () => {
  const issuer = "https://fixture.clerk.accounts.dev";
  const binding = {
    issuer,
    subject: "user_fixture",
    sessionId: "sess_fixture",
  };
  const config = {
    enabled: true,
    issuer,
    secretKey: "sk_test_fixture",
    jwtKey: "public key",
    authorizedParties: ["https://fixo.example.test"],
  };
  const fixture = () => {
    const session = {
      id: binding.sessionId,
      userId: binding.subject,
      status: "active",
      expireAt: Date.now() + 60000,
      abandonAt: Date.now() + 60000,
      actor: null,
    };
    const user = {
      id: binding.subject,
      banned: false,
      locked: false,
      deprovisioned: false,
      primaryEmailAddressId: "email_fixture",
      emailAddresses: [
        {
          id: "email_fixture",
          emailAddress: "private@example.test",
          verification: { status: "verified" },
        },
      ],
    };
    const gateway = {
      sessions: { getSession: jest.fn().mockResolvedValue(session) },
      users: { getUser: jest.fn().mockResolvedValue(user) },
    };
    return {
      session,
      user,
      gateway,
      policy: new ClerkSessionPolicy(config, gateway),
    };
  };
  it("accepts an active matching session with a verified primary email without returning identity metadata", async () => {
    const { policy, gateway } = fixture();
    await expect(policy.assertValid(binding)).resolves.toBeUndefined();
    expect(gateway.sessions.getSession).toHaveBeenCalledWith("sess_fixture");
    expect(gateway.users.getUser).toHaveBeenCalledWith("user_fixture");
  });
  it.each(["revoked", "ended", "expired", "pending"])(
    "rejects provider status %s",
    async (status) => {
      const { policy, session } = fixture();
      session.status = status;
      await expect(policy.assertValid(binding)).rejects.toThrow(
        UnauthorizedException,
      );
    },
  );
  it.each(["banned", "locked", "deprovisioned"] as const)(
    "rejects %s accounts",
    async (flag) => {
      const { policy, user } = fixture();
      user[flag] = true;
      await expect(policy.assertValid(binding)).rejects.toThrow(
        UnauthorizedException,
      );
    },
  );
  it("rejects a session belonging to another user", async () => {
    const { policy, session } = fixture();
    session.userId = "user_other";
    await expect(policy.assertValid(binding)).rejects.toThrow(
      UnauthorizedException,
    );
  });
  it("rejects mismatched account and missing primary verification", async () => {
    const { policy, user } = fixture();
    user.id = "user_other";
    await expect(policy.assertValid(binding)).rejects.toThrow(
      UnauthorizedException,
    );
    user.id = binding.subject;
    user.emailAddresses[0].verification.status = "unverified";
    await expect(policy.assertValid(binding)).rejects.toThrow(
      UnauthorizedException,
    );
  });
  it.each(["expireAt", "abandonAt"] as const)(
    "rejects %s in the past or malformed",
    async (field) => {
      const { policy, session } = fixture();
      session[field] = Date.now() - 1;
      await expect(policy.assertValid(binding)).rejects.toThrow(
        UnauthorizedException,
      );
      session[field] = NaN;
      await expect(policy.assertValid(binding)).rejects.toThrow(
        UnauthorizedException,
      );
    },
  );
  it("rejects impersonation even when the session is active", async () => {
    const { policy, session } = fixture();
    Object.assign(session, { actor: { sub: "user_actor" } });
    await expect(policy.assertValid(binding)).rejects.toThrow(
      UnauthorizedException,
    );
  });
  it("never calls the provider when disabled or the issuer does not match", async () => {
    const { gateway } = fixture();
    await expect(
      new ClerkSessionPolicy(
        { ...config, enabled: false },
        gateway,
      ).assertValid(binding),
    ).rejects.toThrow(ServiceUnavailableException);
    await expect(
      new ClerkSessionPolicy(config, gateway).assertValid({
        ...binding,
        issuer: "https://other.example.test",
      }),
    ).rejects.toThrow(UnauthorizedException);
    expect(gateway.users.getUser).not.toHaveBeenCalled();
  });
  it("fails closed when secret/origin configuration is missing", async () => {
    const { gateway } = fixture();
    for (const change of [
      { secretKey: "" },
      { authorizedParties: [] },
      { authorizedParties: ["https://example.test/path"] },
    ]) {
      await expect(
        new ClerkSessionPolicy({ ...config, ...change }, gateway).assertValid(
          binding,
        ),
      ).rejects.toThrow(ServiceUnavailableException);
    }
    expect(gateway.sessions.getSession).not.toHaveBeenCalled();
  });
  it("sanitizes provider failures and distinguishes deleted sessions from outages", async () => {
    const { policy, gateway } = fixture();
    gateway.sessions.getSession.mockRejectedValue({
      status: 404,
      message: "private provider data",
    });
    await expect(policy.assertValid(binding)).rejects.toThrow(
      UnauthorizedException,
    );
    gateway.sessions.getSession.mockRejectedValue({
      status: 503,
      message: "private provider data",
    });
    await expect(policy.assertValid(binding)).rejects.toThrow(
      ServiceUnavailableException,
    );
    await expect(policy.assertValid(binding)).rejects.not.toThrow(
      "private provider data",
    );
  });
  it("bounds provider wait and clears its timeout after successful reads", async () => {
    jest.useFakeTimers();
    try {
      const { policy, gateway } = fixture();
      gateway.sessions.getSession.mockReturnValue(new Promise(() => {}));
      const result = expect(policy.assertValid(binding)).rejects.toThrow(
        ServiceUnavailableException,
      );
      await jest.advanceTimersByTimeAsync(5001);
      await result;
      expect(jest.getTimerCount()).toBe(0);
    } finally {
      jest.useRealTimers();
    }
  });
});
