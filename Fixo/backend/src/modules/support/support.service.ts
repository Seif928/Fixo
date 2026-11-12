import {
  Injectable,
  ForbiddenException,
  NotFoundException,
  BadRequestException,
  UnauthorizedException,
} from "@nestjs/common";
import { PrismaService } from "../../prisma/prisma.service";
@Injectable()
export class SupportService {
  constructor(private readonly db: PrismaService) {}
  private async active(userId: string) {
    const user = await this.db.user.findUnique({
      where: { id: userId },
      select: { isDeleted: true },
    });
    if (!user || user.isDeleted)
      throw new UnauthorizedException("Account unavailable.");
  }
  async list(userId: string, admin = false) {
    await this.active(userId);
    return {
      items: await this.db.supportThread.findMany({
        where: admin ? {} : { userId },
        orderBy: { updatedAt: "desc" },
        take: 50,
        include: { user: { select: { fullName: true, role: true } } },
      }),
    };
  }
  async create(userId: string, subject: string, body: string) {
    await this.active(userId);
    return this.db.$transaction(async tx => {
      await tx.$executeRaw`SELECT pg_advisory_xact_lock(hashtext(${userId}))`;
      const count = await tx.supportThread.count({where:{userId,closed:false}});
      if(count >= 20) throw new BadRequestException('Please continue an existing support conversation.');
      return tx.supportThread.create({data:{userId,subject:subject.trim(),messages:{create:{senderUserId:userId,body:body.trim()}}}});
    });
  }
  private async thread(id: string, userId: string, admin: boolean) {
    const row = await this.db.supportThread.findUnique({ where: { id } });
    if (!row) throw new NotFoundException("Conversation not found.");
    if (!admin && row.userId !== userId)
      throw new ForbiddenException("Conversation access denied.");
    return row;
  }
  async messages(id: string, userId: string, admin = false) {
    await this.active(userId);
    await this.thread(id, userId, admin);
    const items = await this.db.supportMessage.findMany({
      where: { threadId: id },
      orderBy: [{ createdAt: "desc" }, { id: "desc" }],
      take: 100,
    });
    return { items: items.reverse() };
  }
  async close(id:string) {
    const row = await this.db.supportThread.findUnique({where:{id}});
    if (!row) throw new NotFoundException('Conversation not found.');
    return this.db.supportThread.update({where:{id},data:{closed:true}});
  }
  async send(id: string, userId: string, body: string, admin = false) {
    await this.active(userId);
    return this.db.$transaction(async (tx) => {
      await tx.$queryRaw`SELECT id FROM "SupportThread" WHERE id = ${id} FOR UPDATE`;
      const row = await tx.supportThread.findUnique({ where: { id } });
      if (!row) throw new NotFoundException("Conversation not found.");
      if (!admin && row.userId !== userId)
        throw new ForbiddenException("Conversation access denied.");
      if (row.closed) throw new BadRequestException("Conversation closed.");
      const message = await tx.supportMessage.create({
        data: {
          threadId: id,
          senderUserId: userId,
          body: body.trim(),
          fromAdmin: admin,
        },
      });
      await tx.supportThread.update({
        where: { id },
        data: { updatedAt: new Date() },
      });
      return message;
    });
  }
}
