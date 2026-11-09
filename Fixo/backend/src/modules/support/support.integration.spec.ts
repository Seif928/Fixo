import { PrismaClient } from "@prisma/client";
import { SupportService } from "./support.service";
import { SupportController } from "./support.controller";
import { validateTestDatabaseTarget } from "../../prisma/test-database-safety.util";
import { ForbiddenException } from "@nestjs/common";
describe("Private support boundaries", () => {
  let db: PrismaClient,
    service: SupportService,
    owner: string,
    other: string,
    admin: string,
    thread: string;
  beforeAll(async () => {
    validateTestDatabaseTarget(process.env.TEST_DATABASE_URL);
    db = new PrismaClient({ datasourceUrl: process.env.TEST_DATABASE_URL });
    const result = await db.$queryRaw<
      Array<{ name: string }>
    >`SELECT current_database() as name`;
    if (result[0].name !== "fixo_test") throw new Error("Unsafe database");
    service = new SupportService(db as any);
    owner = (await db.user.create({ data: { fullName: "Support customer" } }))
      .id;
    other = (
      await db.user.create({
        data: { fullName: "Support technician", role: "PRO" },
      })
    ).id;
    admin = (
      await db.user.create({ data: { fullName: "Support administrator" } })
    ).id;
    thread = (
      await service.create(
        owner,
        "Booking question",
        "Can I change my address?",
      )
    ).id;
  });
  afterAll(async () => {
    if (db) {
      if (thread) await db.supportThread.deleteMany({ where: { id: thread } });
      await db.user.deleteMany({
        where: { id: { in: [owner, other, admin].filter(Boolean) } },
      });
      await db.$disconnect();
    }
  });
  it("lists only the signed-in user conversations", async () => {
    expect((await service.list(owner)).items.map((x) => x.id)).toContain(
      thread,
    );
    expect((await service.list(other)).items.map((x) => x.id)).not.toContain(
      thread,
    );
  });
  it("denies cross-account reads and writes", async () => {
    await expect(service.messages(thread, other)).rejects.toThrow(
      ForbiddenException,
    );
    await expect(service.send(thread, other, "intrusion")).rejects.toThrow(
      ForbiddenException,
    );
  });
  it("persists owner messages and administrator replies", async () => {
    await service.send(thread, owner, "Follow up");
    await service.send(thread, admin, "We can help.", true);
    const messages = (await service.messages(thread, owner)).items;
    expect(messages.map((x) => x.body)).toEqual([
      "Can I change my address?",
      "Follow up",
      "We can help.",
    ]);
    expect(messages[2].fromAdmin).toBe(true);
  });
  it("checks administrator authority before reading or replying", async () => {
    const resolve = jest.fn().mockRejectedValue(new ForbiddenException());
    const controller = new SupportController(service, { resolve } as any);
    await expect(controller.all({ sub: other } as any)).rejects.toThrow(
      ForbiddenException,
    );
    await expect(
      controller.reply({ sub: other } as any, thread, {
        body: "pretend admin",
      }),
    ).rejects.toThrow(ForbiddenException);
  });
  it("rejects messages to closed conversations", async () => {
    await db.supportThread.update({
      where: { id: thread },
      data: { closed: true },
    });
    await expect(service.send(thread, owner, "late")).rejects.toThrow(
      "Conversation closed.",
    );
  });
  it('denies support access after account deletion', async () => {
    await db.user.update({where:{id:other},data:{isDeleted:true}});
    await expect(service.list(other)).rejects.toThrow('Account unavailable.');
  });
  it('requires administrator authority before closure', async () => {
    const controller = new SupportController(service,{resolve:jest.fn().mockRejectedValue(new ForbiddenException())} as any);
    await expect(controller.close({sub:other} as any,thread)).rejects.toThrow(ForbiddenException);
  });

});
