import {
  ServiceUnavailableException,
  UnauthorizedException,
} from "@nestjs/common";
import { createClerkClient } from "@clerk/backend";
import {
  ClerkTrialConfiguration,
  ClerkTrialVerifier,
} from "./clerk-trial-verifier";

export interface ClerkSessionBinding {
  issuer: string;
  subject: string;
  sessionId: string;
}
export interface ClerkSessionConfiguration extends ClerkTrialConfiguration {
  secretKey: string;
}
export interface ClerkReadGateway {
  sessions: {
    getSession(
      id: string,
    ): Promise<{
      id: string;
      userId: string;
      status: string;
      expireAt: number;
      abandonAt: number;
      actor?: unknown;
    }>;
  };
  users: {
    getUser(
      id: string,
    ): Promise<{
      id: string;
      banned: boolean;
      locked: boolean;
      deprovisioned?: boolean;
      primaryEmailAddressId: string | null;
      emailAddresses: Array<{
        id: string;
        emailAddress: string;
        verification: { status: string } | null;
      }>;
    }>;
  };
}
export class ClerkSessionPolicy {
  constructor(
    private readonly config: ClerkSessionConfiguration = clerkSessionConfiguration(),
    private readonly gateway?: ClerkReadGateway,
  ) {}

  assertConfigured(): void {
    let originsValid = false;
    try {
      const issuer = new URL(this.config.issuer);
      originsValid =
        issuer.protocol === "https:" &&
        issuer.origin === this.config.issuer &&
        this.config.authorizedParties.length > 0 &&
        this.config.authorizedParties.every((value) => {
          const origin = new URL(value);
          return (
            origin.origin === value &&
            (origin.protocol === "https:" ||
              (origin.protocol === "http:" &&
                ["localhost", "127.0.0.1"].includes(origin.hostname)))
          );
        });
    } catch {
      /* Invalid server configuration never permits a provider request. */
    }
    if (
      !this.config.enabled ||
      !originsValid ||
      !this.config.jwtKey.trim() ||
      !/^sk_(test|live)_\S+$/.test(this.config.secretKey)
    ) {
      throw new ServiceUnavailableException("Clerk trial is not configured.");
    }
  }

  async verify(token: string): Promise<ClerkSessionBinding> {
    this.assertConfigured();
    const identity = await new ClerkTrialVerifier(this.config).verify(token);
    const binding = {
      issuer: this.config.issuer,
      subject: identity.subject,
      sessionId: identity.sessionId,
    };
    await this.assertValid(binding);
    return binding;
  }

  async assertValid(binding: ClerkSessionBinding): Promise<void> {
    this.assertConfigured();
    if (
      !binding ||
      binding.issuer !== this.config.issuer ||
      !/^user_[a-zA-Z0-9]+$/.test(binding.subject) ||
      !/^sess_[a-zA-Z0-9]+$/.test(binding.sessionId)
    ) {
      throw new UnauthorizedException("Clerk account session has ended.");
    }
    const client =
      this.gateway ?? createClerkClient({ secretKey: this.config.secretKey });
    let timer: ReturnType<typeof setTimeout> | undefined;
    try {
      const [session, user] = await Promise.race([
        Promise.all([
          client.sessions.getSession(binding.sessionId),
          client.users.getUser(binding.subject),
        ]),
        new Promise<never>((_, reject) => {
          timer = setTimeout(
            () =>
              reject(
                new ServiceUnavailableException(
                  "Clerk session validation is temporarily unavailable.",
                ),
              ),
            5000,
          );
        }),
      ]);
      const now = Date.now();
      const primary = user.emailAddresses.find(
        (email) => email.id === user.primaryEmailAddressId,
      );
      if (
        session.id !== binding.sessionId ||
        session.userId !== binding.subject ||
        session.status !== "active" ||
        session.actor ||
        !Number.isFinite(session.expireAt) ||
        session.expireAt <= now ||
        !Number.isFinite(session.abandonAt) ||
        session.abandonAt <= now ||
        user.id !== binding.subject ||
        user.banned ||
        user.locked ||
        user.deprovisioned ||
        !primary?.emailAddress ||
        primary.verification?.status !== "verified"
      ) {
        throw new UnauthorizedException("Clerk account session has ended.");
      }
    } catch (error) {
      if (
        error instanceof UnauthorizedException ||
        error instanceof ServiceUnavailableException
      )
        throw error;
      const status =
        error && typeof error === "object" && "status" in error
          ? error.status
          : undefined;
      if (status === 404)
        throw new UnauthorizedException("Clerk account session has ended.");
      throw new ServiceUnavailableException(
        "Clerk session validation is temporarily unavailable.",
      );
    } finally {
      if (timer) clearTimeout(timer);
    }
  }
}

export function clerkSessionConfiguration(): ClerkSessionConfiguration {
  return {
    enabled: process.env.CLERK_TRIAL_ENABLED === "true",
    issuer: process.env.CLERK_ISSUER ?? "",
    jwtKey: (process.env.CLERK_JWT_KEY ?? "").replace(/\\n/g, "\n"),
    authorizedParties: (process.env.CLERK_AUTHORIZED_PARTIES ?? "")
      .split(",")
      .map((value) => value.trim())
      .filter(Boolean),
    secretKey: process.env.CLERK_SECRET_KEY ?? "",
  };
}
