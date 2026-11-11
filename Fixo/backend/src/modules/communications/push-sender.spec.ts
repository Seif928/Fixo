import { PushSender } from "./push.service";

jest.mock("firebase-admin/app", () => ({
  getApps: () => [
    {
      name: "fixo-device-push",
      options: {
        credential: {
          getAccessToken: async () => ({
            access_token: "fixture-oauth",
            expires_in: 3600,
          }),
        },
      },
    },
  ],
  cert: jest.fn(),
  initializeApp: jest.fn(),
}));

describe("FCM direct-send target compatibility", () => {
  const payload = {
    notification: { title: "FIXO", body: "Booking update" },
    data: { bookingId: "fixture-booking" },
  };
  const saved = {
    project: process.env.FIREBASE_PROJECT_ID,
    account: process.env.FIREBASE_SERVICE_ACCOUNT_JSON,
  };
  let request: jest.SpyInstance;
  beforeEach(() => {
    process.env.FIREBASE_PROJECT_ID = "fixture-project";
    process.env.FIREBASE_SERVICE_ACCOUNT_JSON = JSON.stringify({
      project_id: "fixture-project",
      client_email: "fixture@example.test",
      private_key: "fixture-key",
    });
    request = jest
      .spyOn(global, "fetch")
      .mockResolvedValue(new Response("{}", { status: 200 }));
  });
  afterEach(() => {
    request.mockRestore();
  });
  afterAll(() => {
    if (saved.project === undefined) delete process.env.FIREBASE_PROJECT_ID;
    else process.env.FIREBASE_PROJECT_ID = saved.project;
    if (saved.account === undefined)
      delete process.env.FIREBASE_SERVICE_ACCOUNT_JSON;
    else process.env.FIREBASE_SERVICE_ACCOUNT_JSON = saved.account;
  });
  it.each(["c", "d", "e", "f"])(
    "sends a canonical %s-prefixed Firebase Installation ID in the fid field",
    async (prefix) => {
      const fid = prefix + "Ab0_9-".repeat(3) + "XYZ";
      expect(fid.length).toBe(22);
      await new PushSender().send([fid], payload);
      const body = JSON.parse(request.mock.calls[0][1].body as string);
      expect(body.message).toEqual({ fid, ...payload });
      expect(body.message).not.toHaveProperty("token");
    },
  );
  it("preserves older FCM registration-token targets", async () => {
    const token = "fixture-legacy-registration-token".repeat(5);
    await new PushSender().send([token], payload);
    expect(JSON.parse(request.mock.calls[0][1].body as string).message).toEqual(
      { token, ...payload },
    );
  });
  it("removes unregistered FIDs using the same stored identifier", async () => {
    const fid = "c" + "a".repeat(21);
    request.mockResolvedValue(
      new Response(
        JSON.stringify({ error: { details: [{ errorCode: "UNREGISTERED" }] } }),
        { status: 404 },
      ),
    );
    expect(await new PushSender().send([fid], payload)).toEqual({
      acceptedCount: 0,
      invalidTokens: [fid],
    });
  });
});
