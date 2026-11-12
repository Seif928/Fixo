import {
  ConflictException,
  Injectable,
  ServiceUnavailableException,
  UnauthorizedException,
} from "@nestjs/common";
import { PrismaService } from "../../prisma/prisma.service";
import { AuthService } from "./auth.service";
import { FirebaseTokenVerifier } from "./firebase-identity.service";
import { ClerkSessionPolicy } from "./clerk-session-policy.service";

/** Opt-in trial: only an explicit proof of BOTH identities can create a link. */
@Injectable()
export class ClerkIdentityService {
  constructor(
    private readonly db: PrismaService,
    private readonly firebase: FirebaseTokenVerifier,
    private readonly sessions: AuthService,
    private readonly clerk: ClerkSessionPolicy,
  ) {}

  private ready(): void {
    this.clerk.assertConfigured();
    if (!this.db.isDatabaseConnected())
      throw new ServiceUnavailableException(
        "Clerk trial requires database persistence.",
      );
  }

  async link(
    userId: string,
    firebaseIdToken: string,
    clerkToken: string,
  ): Promise<{ linked: true }> {
    this.ready();
    const identity = await this.firebase.verify(firebaseIdToken);
    const now = Math.floor(Date.now() / 1000);
    if (
      !identity.email_verified ||
      !Number.isSafeInteger(identity.auth_time) ||
      identity.auth_time < now - 300 ||
      identity.auth_time > now + 60
    ) {
      throw new UnauthorizedException(
        "Sign in again with your existing FIXO account before linking.",
      );
    }
    const binding = await this.clerk.verify(clerkToken);
    try {
      await this.db.$transaction(async (tx) => {
        // Serializes links for this user with deletion/profile changes that lock the same row.
        await tx.$queryRaw`SELECT id FROM "User" WHERE id = ${userId} FOR UPDATE`;
        const user = await tx.user.findUnique({ where: { id: userId } });
        if (
          !user ||
          user.isDeleted ||
          !user.firebaseUid ||
          user.firebaseUid !== identity.uid
        ) {
          throw new UnauthorizedException(
            "The existing FIXO identity could not be confirmed.",
          );
        }
        const linked = await tx.clerkIdentityLink.findUnique({
          where: {
            issuer_subject: {
              issuer: binding.issuer,
              subject: binding.subject,
            },
          },
        });
        if (linked) {
          if (linked.userId !== userId)
            throw new ConflictException(
              "This identity is already linked to a different account.",
            );
          return;
        }
        await tx.clerkIdentityLink.create({
          data: { userId, issuer: binding.issuer, subject: binding.subject },
        });
      });
    } catch (error) {
      if (
        error &&
        typeof error === "object" &&
        "code" in error &&
        error.code === "P2002"
      ) {
        throw new ConflictException(
          "An identity is already linked. Existing links cannot be replaced.",
        );
      }
      throw error;
    }
    return { linked: true };
  }

  async exchange(clerkToken: string) {
    this.ready();
    const binding = await this.clerk.verify(clerkToken);
    const linked = await this.db.clerkIdentityLink.findUnique({
      where: {
        issuer_subject: { issuer: binding.issuer, subject: binding.subject },
      },
    });
    if (!linked)
      throw new UnauthorizedException(
        "Sign in with your existing FIXO method and link this identity first.",
      );
    return this.sessions.issueClerkUserSession(linked.userId, binding);
  }
}
