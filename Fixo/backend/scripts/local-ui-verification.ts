// Local test harness only; never imported by the production application.
import { NestFactory } from "@nestjs/core";
import { ValidationPipe } from "@nestjs/common";
import { NestExpressApplication } from "@nestjs/platform-express";
import { AppModule } from "../src/app.module";
import { PrismaService } from "../src/prisma/prisma.service";
import { seedCatalog } from "../src/prisma/seed-catalog";
import {
  assertCurrentDatabaseIsTest,
  validateTestDatabaseTarget,
} from "../src/prisma/test-database-safety.util";
import { AllExceptionsFilter } from "../src/common/filters/all-exceptions.filter";

async function main() {
  if (
    process.env.NODE_ENV !== "test" ||
    process.env.FIXO_TEST_FORCE_PRISMA !== "true"
  ) {
    throw new Error(
      "Local UI verification requires explicit PostgreSQL test mode.",
    );
  }
  validateTestDatabaseTarget(process.env.TEST_DATABASE_URL);
  if (process.env.DATABASE_URL !== process.env.TEST_DATABASE_URL) {
    throw new Error(
      "DATABASE_URL must exactly match validated local TEST_DATABASE_URL.",
    );
  }
  const app = await NestFactory.create<NestExpressApplication>(AppModule);
  try {
    app.useBodyParser("json", { limit: "3mb" });
    app.setGlobalPrefix("api/v1");
    app.useGlobalPipes(
      new ValidationPipe({
        whitelist: true,
        forbidNonWhitelisted: true,
        transform: true,
      }),
    );
    app.useGlobalFilters(new AllExceptionsFilter());
    await app.init();
    const db = app.get(PrismaService);
    await assertCurrentDatabaseIsTest(db);
    await seedCatalog(db);
    await app.listen(3002, "127.0.0.1");
    const stop = async () => {
      await app.close();
    };
    process.once("SIGINT", stop);
    process.once("SIGTERM", stop);
    console.log("LOCAL_UI_TEST_READY: loopback port 3002 / fixo_test");
  } catch (error) {
    await app.close();
    throw error;
  }
}
main().catch((error) => {
  console.error(error.message);
  process.exitCode = 1;
});
