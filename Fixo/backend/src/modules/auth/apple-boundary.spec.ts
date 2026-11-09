import { UnauthorizedException } from "@nestjs/common";
import { FirebaseIdentityService } from "./firebase-identity.service";

describe("Apple identity boundary", () => {
  const victim = { id: "fixture-user", fullName: "Fixture User" };
  let db: any;
  let verifier: any;
  let sessions: any;
  let service: FirebaseIdentityService;
  beforeEach(() => {
    db = {
      isDatabaseConnected: () => true,
      user: {
        findUnique: jest.fn().mockResolvedValue(victim),
        create: jest.fn(),
        update: jest.fn(),
      },
    };
    verifier = {
      verify: jest
        .fn()
        .mockRejectedValue(new UnauthorizedException("Invalid token")),
    };
    sessions = {
      issueVerifiedUserSession: jest
        .fn()
        .mockResolvedValue({ accessToken: "fixture" }),
    };
    service = new FirebaseIdentityService(db, verifier, sessions);
  });
  it.each([
    {},
    { email: "victim@example.test" },
    {
      idToken: "invalid-provider-token-long-enough",
      email: "victim@example.test",
    },
  ])(
    "rejects unproved identity before any database access: %j",
    async (dto) => {
      await expect(service.exchangeApple(dto)).rejects.toThrow(
        UnauthorizedException,
      );
      expect(db.user.findUnique).not.toHaveBeenCalled();
      expect(sessions.issueVerifiedUserSession).not.toHaveBeenCalled();
    },
  );
  it("requires Apple provider for the Apple-specific exchange", async () => {
    verifier.verify.mockResolvedValue({
      uid: "google-user",
      email: "fixture@example.test",
      email_verified: true,
      auth_time: 1234,
      firebase: { sign_in_provider: "google.com" },
    });
    await expect(
      service.exchangeApple({ idToken: "signed-token-long-enough" }),
    ).rejects.toThrow(UnauthorizedException);
    expect(sessions.issueVerifiedUserSession).not.toHaveBeenCalled();
  });
  it("retains signed provider authentication time and UID", async () => {
    verifier.verify.mockResolvedValue({
      uid: "apple-fixture",
      email: "fixture@privaterelay.appleid.com",
      email_verified: true,
      auth_time: 1234,
      firebase: { sign_in_provider: "apple.com" },
    });
    await service.exchangeApple({ idToken: "signed-token-long-enough" });
    expect(db.user.findUnique).toHaveBeenCalledWith({
      where: { firebaseUid: "apple-fixture" },
    });
    expect(sessions.issueVerifiedUserSession).toHaveBeenCalledWith(
      victim.id,
      1234,
    );
  });
});
