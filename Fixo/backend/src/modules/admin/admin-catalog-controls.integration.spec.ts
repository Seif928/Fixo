import { INestApplication, ValidationPipe } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import { randomUUID } from 'crypto';
import * as dotenv from 'dotenv';
import * as path from 'path';
import { PrismaModule } from '../../prisma/prisma.module';
import { PrismaService } from '../../prisma/prisma.service';
import {
  assertCurrentDatabaseIsTest,
  validateTestDatabaseTarget,
} from '../../prisma/test-database-safety.util';
import { AuthService } from '../auth/auth.service';
import { FirebaseSessionPolicy } from '../auth/firebase-session-policy.service';
import { AdminAccessModule } from './admin-access.module';
import { ServicesModule } from '../services/services.module';
import { BookingsModule } from '../bookings/bookings.module';
import { PushService } from '../communications/push.service';

dotenv.config({ path: path.resolve(__dirname, '../../../.env') });

describe('Admin Catalog Controls (Guarded PostgreSQL)', () => {
  let app: INestApplication;
  let db: PrismaService;
  let auth: AuthService;
  let url: string;
  let owner: any;
  let outsider: any;
  let customer: any;
  let category: any;
  let zone: any;
  let address: any;

  const users: string[] = [];
  const drafts: string[] = [];
  const offerings: string[] = [];
  const bookings: string[] = [];
  const identities = new Map<string, string>();
  const notify = jest.fn(async () => ({ accepted: false }));
  const priorOwner = process.env.FIXO_OWNER_EMAIL;

  beforeAll(async () => {
    validateTestDatabaseTarget(process.env.TEST_DATABASE_URL);
    process.env.DATABASE_URL = process.env.TEST_DATABASE_URL;
    process.env.FIXO_TEST_FORCE_PRISMA = 'true';
    process.env.ALLOW_IN_MEMORY_FALLBACK = 'false';

    const module = await Test.createTestingModule({
      imports: [
        PrismaModule,
        AdminAccessModule,
        ServicesModule,
        BookingsModule,
      ],
    })
      .overrideProvider(FirebaseSessionPolicy)
      .useValue({
        readVerifiedAccount: async (uid: string) => ({
          uid,
          email: identities.get(uid),
        }),
      })
      .overrideProvider(PushService)
      .useValue({ notify })
      .compile();

    app = module.createNestApplication();
    app.setGlobalPrefix('api/v1');
    app.useGlobalPipes(
      new ValidationPipe({
        transform: true,
        whitelist: true,
        forbidNonWhitelisted: true,
      }),
    );
    await app.init();
    await app.listen(0, '127.0.0.1');
    url = await app.getUrl();
    db = module.get(PrismaService);
    auth = module.get(AuthService);
    await assertCurrentDatabaseIsTest(db);

    const testCatSlug = `cat-test-${randomUUID().slice(0, 8)}`;
    category = await db.serviceCategory.create({
      data: {
        slug: testCatSlug,
        nameEn: 'Plumbing & Water Fixtures',
        nameAr: 'سباكة وأدوات صحية',
        subtitleEn: 'Pipes, taps and leak repair',
        subtitleAr: 'مواسير وحنفيات وإصلاح تسريبات',
        iconName: 'plumbing',
        startingPriceEgp: 150,
      },
    });

    const testZoneSlug = `zone-test-${randomUUID().slice(0, 8)}`;
    zone = await db.coverageZone.create({
      data: {
        slug: testZoneSlug,
        nameEn: 'Maadi & Degla',
        nameAr: 'المعادي ودجلة',
        governorate: 'Cairo',
      },
    });
  });

  const createUser = async (
    role: 'CUSTOMER' | 'ADMIN' | 'PRO' = 'CUSTOMER',
  ) => {
    const uid = randomUUID();
    const u = await db.user.create({
      data: {
        firebaseUid: uid,
        email: `${uid}@example.test`,
        fullName: `Fixture ${role}`,
        role,
      },
    });
    identities.set(uid, u.email!);
    users.push(u.id);
    return u;
  };

  beforeEach(async () => {
    notify.mockClear();
    owner = await createUser();
    outsider = await createUser('ADMIN');
    customer = await createUser('CUSTOMER');

    process.env.FIXO_OWNER_EMAIL = owner.email;

    address = await db.customerAddress.create({
      data: {
        userId: customer.id,
        zoneId: zone.id,
        label: 'Home',
        buildingLine: '12 Road 9, Degla',
        districtLine: 'Maadi',
      },
    });
  });

  afterEach(async () => {
    if (bookings.length > 0) {
      await db.paymentRecord.deleteMany({
        where: { bookingId: { in: bookings } },
      });
      await db.bookingStatusEvent.deleteMany({
        where: { bookingId: { in: bookings } },
      });
      await db.booking.deleteMany({
        where: { id: { in: bookings.splice(0) } },
      });
    }

    if (drafts.length > 0) {
      await db.adminCatalogDraft.deleteMany({
        where: { id: { in: drafts.splice(0) } },
      });
    }

    if (offerings.length > 0) {
      await db.serviceOffering.deleteMany({
        where: { id: { in: offerings.splice(0) } },
      });
    }

    if (address) {
      await db.customerAddress.deleteMany({
        where: { userId: { in: users } },
      });
    }

    await db.adminAuditLog.deleteMany();
    await db.adminMembership.deleteMany();
    await db.user.deleteMany({ where: { id: { in: users.splice(0) } } });
    identities.clear();
  });

  afterAll(async () => {
    if (priorOwner === undefined) delete process.env.FIXO_OWNER_EMAIL;
    else process.env.FIXO_OWNER_EMAIL = priorOwner;

    if (category) {
      await db.serviceCategory.delete({ where: { id: category.id } });
    }
    if (zone) {
      await db.coverageZone.delete({ where: { id: zone.id } });
    }
    if (app) await app.close();
  });

  const request = async (
    actor: any,
    route: string,
    method = 'GET',
    body?: object,
    age = 0,
  ) => {
    const session = actor
      ? await auth.issueVerifiedUserSession(
          actor.id,
          Math.floor(Date.now() / 1000) - age,
        )
      : null;
    return fetch(`${url}/api/v1${route}`, {
      method,
      headers: {
        'Content-Type': 'application/json',
        ...(session ? { Authorization: `Bearer ${session.accessToken}` } : {}),
      },
      ...(body ? { body: JSON.stringify(body) } : {}),
    });
  };

  it('denies anonymous and ordinary users from mutating the catalog', async () => {
    const unauth = await request(null, '/admin/catalog', 'POST', {
      titleEn: 'Test Service',
      titleAr: 'خدمة تجريبية',
      descriptionEn: 'Description',
      descriptionAr: 'الوصف',
      categorySlug: category.slug,
    });
    expect(unauth.status).toBe(401);

    const forbidden = await request(outsider, '/admin/catalog', 'POST', {
      titleEn: 'Test Service',
      titleAr: 'خدمة تجريبية',
      descriptionEn: 'Description',
      descriptionAr: 'الوصف',
      categorySlug: category.slug,
    });
    expect(forbidden.status).toBe(403);
  });

  it('rejects stale admin sessions older than 15 minutes', async () => {
    const staleRes = await request(
      owner,
      '/admin/catalog',
      'POST',
      {
        titleEn: 'Stale Service',
        titleAr: 'خدمة قديمة الجلسة',
        descriptionEn: 'Stale description',
        descriptionAr: 'وصف جلسة قديمة',
        categorySlug: category.slug,
      },
      901, // 15 mins + 1 sec
    );
    expect(staleRes.status).toBe(403);
    const err = await staleRes.json();
    expect(err.code).toBe('ADMIN_REAUTH_REQUIRED');
  });

  it('creates custom private service draft with explicit bilingual fields and unique slug', async () => {
    // 1. Missing bilingual names rejected
    const badReq1 = await request(owner, '/admin/catalog', 'POST', {
      titleEn: 'Water Leak Repair',
      descriptionEn: 'Fixing water leaks in bathroom',
      descriptionAr: 'إصلاح تسريبات المياه',
      categorySlug: category.slug,
    });
    expect(badReq1.status).toBe(400);

    // 2. Successful creation with un-fabricated prices (null)
    const customSlug = `water-leak-${randomUUID().slice(0, 6)}`;
    const createRes = await request(owner, '/admin/catalog', 'POST', {
      slug: customSlug,
      titleEn: 'Water Leak Detection & Repair',
      titleAr: 'كشف وإصلاح تسريبات المياه',
      descriptionEn: 'Precision ultrasound leak detection and pipe sealing',
      descriptionAr: 'كشف تسريب بالموجات الصوتية وإصلاح دقيق للمواسير',
      categorySlug: category.slug,
    });
    expect(createRes.status).toBe(201);
    const draft = await createRes.json();
    drafts.push(draft.id);

    expect(draft.id).toBeDefined();
    expect(draft.slug).toBe(customSlug);
    expect(draft.version).toBe(1);
    expect(draft.publishedVersion).toBeNull();
    expect(draft.offeringId).toBeNull();
    expect(draft.isActive).toBe(true);
    // Explicitly un-fabricated pricing & duration
    expect(draft.baseInspectionEgp).toBeNull();
    expect(draft.serviceFeeEgp).toBeNull();
    expect(draft.estimatedDurationMins).toBeNull();

    // Verify audit log
    const auditLogs = await (db as any).adminAuditLog.findMany({
      where: { entityId: draft.id, action: 'CATALOG_DRAFT_CREATED' },
    });
    expect(auditLogs).toHaveLength(1);
    expect(auditLogs[0].actorUserId).toBe(owner.id);

    // 3. Collision protection: duplicate slug rejected with 409
    const dupRes = await request(owner, '/admin/catalog', 'POST', {
      slug: customSlug,
      titleEn: 'Duplicate Water Leak Service',
      titleAr: 'خدمة تسريب مكررة',
      descriptionEn: 'Duplicate',
      descriptionAr: 'مكرر',
      categorySlug: category.slug,
    });
    expect(dupRes.status).toBe(409);
    const dupBody = await dupRes.json();
    expect(dupBody.code).toBe('ADMIN_CATALOG_SLUG_EXISTS');
  });

  it('safely handles draft lifecycle: publish, deactivation, and reactivation with booking integrity', async () => {
    // 1. Create a draft
    const slug = `pipe-welding-${randomUUID().slice(0, 6)}`;
    const createRes = await request(owner, '/admin/catalog', 'POST', {
      slug,
      titleEn: 'PPR Pipe Thermal Welding',
      titleAr: 'لحام حراري لمواسير البي بي آر',
      descriptionEn: 'Professional thermal fusion for cold and hot PPR water lines',
      descriptionAr: 'لحام حراري احترافي لشبكات المياه الساخنة والباردة',
      categorySlug: category.slug,
    });
    expect(createRes.status).toBe(201);
    const draft = await createRes.json();
    drafts.push(draft.id);

    // 2. Cannot publish without pricing
    const pubFail = await request(
      owner,
      `/admin/catalog/${draft.id}/publish`,
      'POST',
      { version: draft.version },
    );
    expect(pubFail.status).toBe(400);
    const pubFailBody = await pubFail.json();
    expect(pubFailBody.code).toBe('ADMIN_CATALOG_PRICING_REQUIRED');

    // 3. Set draft pricing & duration
    const updateRes = await request(
      owner,
      `/admin/catalog/${draft.id}`,
      'PUT',
      {
        version: draft.version,
        baseInspectionEgp: 150,
        serviceFeeEgp: 300,
        estimatedDurationMins: 90,
      },
    );
    expect(updateRes.status).toBe(200);
    const updatedDraft = await updateRes.json();
    expect(updatedDraft.version).toBe(2);

    // 4. Publish service offering
    const pubRes = await request(
      owner,
      `/admin/catalog/${draft.id}/publish`,
      'POST',
      { version: updatedDraft.version },
    );
    expect(pubRes.status).toBe(201);
    const publishedDraft = await pubRes.json();
    expect(publishedDraft.publishedVersion).toBe(2);
    expect(publishedDraft.offeringId).toBeTruthy();
    expect(publishedDraft.isActive).toBe(true);
    offerings.push(publishedDraft.offeringId);

    // Verify service appears in public listing
    const publicServicesRes = await fetch(`${url}/api/v1/services`);
    expect(publicServicesRes.status).toBe(200);
    const publicServices = await publicServicesRes.json();
    const foundInPublic = publicServices.items.some(
      (s: any) => s.id === publishedDraft.offeringId,
    );
    expect(foundInPublic).toBe(true);

    // 5. Customer creates a booking for this service
    const scheduledDate = new Date(Date.now() + 86400000).toISOString();
    const bookRes = await request(customer, '/bookings', 'POST', {
      offeringId: publishedDraft.offeringId,
      addressId: address.id,
      scheduledDate,
      timeWindow: 'MORNING_09_12',
    });
    expect(bookRes.status).toBe(201);
    const booking = await bookRes.json();
    bookings.push(booking.id);
    expect(booking.offering.id).toBe(publishedDraft.offeringId);

    // 6. Deactivate the service
    // Stale version rejected
    const staleDeact = await request(
      owner,
      `/admin/catalog/${draft.id}/deactivate`,
      'POST',
      { version: 1 },
    );
    expect(staleDeact.status).toBe(409);

    // Valid deactivation
    const deactRes = await request(
      owner,
      `/admin/catalog/${draft.id}/deactivate`,
      'POST',
      { version: publishedDraft.version },
    );
    expect(deactRes.status).toBe(201);
    const deactivatedDraft = await deactRes.json();
    expect(deactivatedDraft.isActive).toBe(false);
    expect(deactivatedDraft.version).toBe(publishedDraft.version + 1);

    // Verify DB offering is inactive
    const offeringInDb = await db.serviceOffering.findUniqueOrThrow({
      where: { id: publishedDraft.offeringId },
    });
    expect(offeringInDb.isActive).toBe(false);

    // Verify audit event
    const deactAudit = await (db as any).adminAuditLog.findFirst({
      where: {
        entityId: draft.id,
        action: 'CATALOG_SERVICE_DEACTIVATED',
      },
    });
    expect(deactAudit).toBeTruthy();

    // 7. Inactive service DISAPPEARS from public listing
    const publicServicesAfterDeact = await (
      await fetch(`${url}/api/v1/services`)
    ).json();
    const foundAfterDeact = publicServicesAfterDeact.items.some(
      (s: any) => s.id === publishedDraft.offeringId,
    );
    expect(foundAfterDeact).toBe(false);

    // 8. New bookings for the deactivated service are REJECTED
    const rejectBookRes = await request(customer, '/bookings', 'POST', {
      offeringId: publishedDraft.offeringId,
      addressId: address.id,
      scheduledDate,
      timeWindow: 'EVENING_17_20',
    });
    expect(rejectBookRes.status).toBe(400);
    const rejectBookBody = await rejectBookRes.json();
    expect(rejectBookBody.message).toContain(
      'Selected service offering is not currently active.',
    );

    // 9. Existing booking remains readable and operable
    const getExistingBooking = await request(
      customer,
      `/bookings/${booking.id}`,
    );
    expect(getExistingBooking.status).toBe(200);
    const existingBookingBody = await getExistingBooking.json();
    expect(existingBookingBody.id).toBe(booking.id);
    expect(existingBookingBody.offering.id).toBe(publishedDraft.offeringId);
    expect(existingBookingBody.pricing.totalEgp).toBe(450); // 150 + 300 preserved

    // 10. Reactivate the service
    const reactRes = await request(
      owner,
      `/admin/catalog/${draft.id}/reactivate`,
      'POST',
      { version: deactivatedDraft.version },
    );
    expect(reactRes.status).toBe(201);
    const reactivatedDraft = await reactRes.json();
    expect(reactivatedDraft.isActive).toBe(true);
    expect(reactivatedDraft.version).toBe(deactivatedDraft.version + 1);

    // Verify DB offering is active
    const offeringAfterReact = await db.serviceOffering.findUniqueOrThrow({
      where: { id: publishedDraft.offeringId },
    });
    expect(offeringAfterReact.isActive).toBe(true);

    // Verify service REAPPEARS in public listing
    const publicServicesAfterReact = await (
      await fetch(`${url}/api/v1/services`)
    ).json();
    const foundAfterReact = publicServicesAfterReact.items.some(
      (s: any) => s.id === publishedDraft.offeringId,
    );
    expect(foundAfterReact).toBe(true);

    // New booking succeeds again
    const secondBookRes = await request(customer, '/bookings', 'POST', {
      offeringId: publishedDraft.offeringId,
      addressId: address.id,
      scheduledDate,
      timeWindow: 'EVENING_17_20',
    });
    expect(secondBookRes.status).toBe(201);
    const secondBooking = await secondBookRes.json();
    bookings.push(secondBooking.id);
    expect(secondBooking.offering.id).toBe(publishedDraft.offeringId);
  });

  it('rejects reactivating a service if its category is inactive', async () => {
    // Create, price, and publish
    const slug = `inactive-cat-${randomUUID().slice(0, 6)}`;
    const createRes = await request(owner, '/admin/catalog', 'POST', {
      slug,
      titleEn: 'Inactive Category Service',
      titleAr: 'خدمة فئة معطلة',
      descriptionEn: 'Testing category deactivation safeguard',
      descriptionAr: 'اختبار حماية تعطيل الفئة',
      categorySlug: category.slug,
      baseInspectionEgp: 100,
      serviceFeeEgp: 150,
      estimatedDurationMins: 45,
    });
    expect(createRes.status).toBe(201);
    const draft = await createRes.json();
    drafts.push(draft.id);

    const pubRes = await request(
      owner,
      `/admin/catalog/${draft.id}/publish`,
      'POST',
      { version: draft.version },
    );
    expect(pubRes.status).toBe(201);
    const pubDraft = await pubRes.json();
    offerings.push(pubDraft.offeringId);

    // Deactivate service
    const deactRes = await request(
      owner,
      `/admin/catalog/${draft.id}/deactivate`,
      'POST',
      { version: pubDraft.version },
    );
    expect(deactRes.status).toBe(201);
    const deactDraft = await deactRes.json();

    // Deactivate the category in DB
    await db.serviceCategory.update({
      where: { id: category.id },
      data: { isActive: false },
    });

    try {
      // Attempt reactivation should fail with 400
      const reactRes = await request(
        owner,
        `/admin/catalog/${draft.id}/reactivate`,
        'POST',
        { version: deactDraft.version },
      );
      expect(reactRes.status).toBe(400);
      const err = await reactRes.json();
      expect(err.message).toContain('The service category is inactive.');
    } finally {
      // Restore category active state for test cleanup
      await db.serviceCategory.update({
        where: { id: category.id },
        data: { isActive: true },
      });
    }
  });

  it('rolls back mutations cleanly when an error occurs during transaction', async () => {
    const access = app.get(AdminAccessModule);
    const countBefore = await (db as any).adminAuditLog.count();
    const draftsBefore = await db.adminCatalogDraft.count();

    const badDraftSlug = `rollback-test-${randomUUID().slice(0, 6)}`;
    // If slug already exists, creation fails and no draft or audit log is committed
    await db.adminCatalogDraft.create({
      data: {
        slug: badDraftSlug,
        categorySlug: category.slug,
        categoryNameEn: category.nameEn,
        categoryNameAr: category.nameAr,
        categoryIcon: category.iconName,
        titleEn: 'Existing Draft',
        titleAr: 'مسودة موجودة',
        descriptionEn: 'Existing',
        descriptionAr: 'موجود',
        version: 1,
        isActive: true,
      },
    });

    const createRes = await request(owner, '/admin/catalog', 'POST', {
      slug: badDraftSlug,
      titleEn: 'Collision Draft',
      titleAr: 'مسودة متعارضة',
      descriptionEn: 'Collision',
      descriptionAr: 'تعارض',
      categorySlug: category.slug,
    });
    expect(createRes.status).toBe(409);

    // Clean up created existing draft
    await db.adminCatalogDraft.delete({ where: { slug: badDraftSlug } });
  });

  it('preserves unpublished draft edits across deactivation/reactivation cycles without premature publication', async () => {
    // 1. Create and price draft at priceA (100 + 200 = 300 EGP)
    const slug = `price-cycle-${randomUUID().slice(0, 6)}`;
    const createRes = await request(owner, '/admin/catalog', 'POST', {
      slug,
      titleEn: 'Price Cycle Service',
      titleAr: 'خدمة دورة الأسعار',
      descriptionEn: 'Testing pending edit preservation across deactivation',
      descriptionAr: 'اختبار الحفاظ على التعديلات المعلقة عبر التعطيل',
      categorySlug: category.slug,
      baseInspectionEgp: 100,
      serviceFeeEgp: 200,
      estimatedDurationMins: 60,
    });
    expect(createRes.status).toBe(201);
    const draft = await createRes.json();
    drafts.push(draft.id);

    // 2. Publish version 1 at priceA
    const pubRes = await request(
      owner,
      `/admin/catalog/${draft.id}/publish`,
      'POST',
      { version: draft.version },
    );
    expect(pubRes.status).toBe(201);
    const publishedA = await pubRes.json();
    offerings.push(publishedA.offeringId);
    expect(publishedA.version).toBe(1);
    expect(publishedA.publishedVersion).toBe(1);

    // Verify offering in DB has priceA (300)
    let offeringDb = await db.serviceOffering.findUniqueOrThrow({
      where: { id: publishedA.offeringId },
    });
    expect(offeringDb.flatPriceEgp).toBe(300);

    // 3. Save an unpublished priceB edit (120 + 280 = 400 EGP)
    const updateRes = await request(
      owner,
      `/admin/catalog/${draft.id}`,
      'PUT',
      {
        version: publishedA.version,
        baseInspectionEgp: 120,
        serviceFeeEgp: 280,
      },
    );
    expect(updateRes.status).toBe(200);
    const draftB = await updateRes.json();
    expect(draftB.version).toBe(2);
    expect(draftB.publishedVersion).toBe(1); // Pending edits: publishedVersion != version

    // Offering in DB still has priceA (300)
    offeringDb = await db.serviceOffering.findUniqueOrThrow({
      where: { id: publishedA.offeringId },
    });
    expect(offeringDb.flatPriceEgp).toBe(300);

    // 4. Deactivate the service
    const deactRes = await request(
      owner,
      `/admin/catalog/${draft.id}/deactivate`,
      'POST',
      { version: draftB.version },
    );
    expect(deactRes.status).toBe(201);
    const deactivatedDraft = await deactRes.json();
    expect(deactivatedDraft.isActive).toBe(false);
    expect(deactivatedDraft.version).toBe(3);
    // Crucial: publishedVersion must NOT jump to 3; it stays 1 because edits are pending!
    expect(deactivatedDraft.publishedVersion).toBe(1);

    // Offering in DB is inactive but price remains priceA (300)
    offeringDb = await db.serviceOffering.findUniqueOrThrow({
      where: { id: publishedA.offeringId },
    });
    expect(offeringDb.isActive).toBe(false);
    expect(offeringDb.flatPriceEgp).toBe(300);

    // 5. Reactivate the service
    const reactRes = await request(
      owner,
      `/admin/catalog/${draft.id}/reactivate`,
      'POST',
      { version: deactivatedDraft.version },
    );
    expect(reactRes.status).toBe(201);
    const reactivatedDraft = await reactRes.json();
    expect(reactivatedDraft.isActive).toBe(true);
    expect(reactivatedDraft.version).toBe(4);
    // Crucial: publishedVersion still stays 1; edits remain pending!
    expect(reactivatedDraft.publishedVersion).toBe(1);

    // Offering in DB is active again, public price remains priceA (300)
    offeringDb = await db.serviceOffering.findUniqueOrThrow({
      where: { id: publishedA.offeringId },
    });
    expect(offeringDb.isActive).toBe(true);
    expect(offeringDb.flatPriceEgp).toBe(300);

    const publicServicesRes = await fetch(`${url}/api/v1/services`);
    const publicServices = await publicServicesRes.json();
    const serviceInPublic = publicServices.items.find(
      (s: any) => s.id === publishedA.offeringId,
    );
    expect(serviceInPublic).toBeDefined();
    expect(serviceInPublic.flatPriceEgp).toBe(300); // priceA remains public!

    // 6. Explicitly publish the current version (4)
    const pubBRes = await request(
      owner,
      `/admin/catalog/${draft.id}/publish`,
      'POST',
      { version: reactivatedDraft.version },
    );
    expect(pubBRes.status).toBe(201);
    const finalPubDraft = await pubBRes.json();
    expect(finalPubDraft.version).toBe(4);
    expect(finalPubDraft.publishedVersion).toBe(4); // Now caught up!

    // Offering in DB now reflects priceB (400)
    offeringDb = await db.serviceOffering.findUniqueOrThrow({
      where: { id: publishedA.offeringId },
    });
    expect(offeringDb.flatPriceEgp).toBe(400);

    // Public listing now shows priceB (400)
    const publicAfterFinal = await (await fetch(`${url}/api/v1/services`)).json();
    const publicServiceFinal = publicAfterFinal.items.find(
      (s: any) => s.id === publishedA.offeringId,
    );
    expect(publicServiceFinal.flatPriceEgp).toBe(400);
  });

  it('rejects an unknown category slug unless both explicit bilingual category names are supplied', async () => {
    const unknownCatSlug = `brand-new-cat-${randomUUID().slice(0, 6)}`;

    // 1. Unknown category with neither name supplied -> 400
    const fail1 = await request(owner, '/admin/catalog', 'POST', {
      titleEn: 'Smart Thermostat Setup',
      titleAr: 'تركيب ثرموستات ذكي',
      descriptionEn: 'Smart home automation installation',
      descriptionAr: 'تركيب أنظمة التحكم المنزلي الذكي',
      categorySlug: unknownCatSlug,
    });
    expect(fail1.status).toBe(400);
    const err1 = await fail1.json();
    expect(err1.code).toBe('ADMIN_CATALOG_CATEGORY_NAMES_REQUIRED');

    // 2. Unknown category with English only -> 400 (never fabricate Arabic from slug)
    const fail2 = await request(owner, '/admin/catalog', 'POST', {
      titleEn: 'Smart Thermostat Setup',
      titleAr: 'تركيب ثرموستات ذكي',
      descriptionEn: 'Smart home automation installation',
      descriptionAr: 'تركيب أنظمة التحكم المنزلي الذكي',
      categorySlug: unknownCatSlug,
      categoryNameEn: 'Smart Home Automation',
    });
    expect(fail2.status).toBe(400);
    const err2 = await fail2.json();
    expect(err2.code).toBe('ADMIN_CATALOG_CATEGORY_NAMES_REQUIRED');

    // 3. Unknown category with both explicit bilingual names -> 201
    const successNew = await request(owner, '/admin/catalog', 'POST', {
      titleEn: 'Smart Thermostat Setup',
      titleAr: 'تركيب ثرموستات ذكي',
      descriptionEn: 'Smart home automation installation',
      descriptionAr: 'تركيب أنظمة التحكم المنزلي الذكي',
      categorySlug: unknownCatSlug,
      categoryNameEn: 'Smart Home Automation',
      categoryNameAr: 'أتمتة المنازل الذكية',
    });
    expect(successNew.status).toBe(201);
    const newDraft = await successNew.json();
    drafts.push(newDraft.id);
    expect(newDraft.categoryNameEn).toBe('Smart Home Automation');
    expect(newDraft.categoryNameAr).toBe('أتمتة المنازل الذكية');

    // 4. Existing known category without extra names -> 201 (reuses stored labels)
    const successExisting = await request(owner, '/admin/catalog', 'POST', {
      titleEn: 'Faucet Replacement',
      titleAr: 'تغيير خلاط مياه',
      descriptionEn: 'Bathroom and kitchen faucet installation',
      descriptionAr: 'تركيب وتغيير خلاطات المطبخ والحمام',
      categorySlug: category.slug,
    });
    expect(successExisting.status).toBe(201);
    const existingDraft = await successExisting.json();
    drafts.push(existingDraft.id);
    expect(existingDraft.categoryNameEn).toBe(category.nameEn);
    expect(existingDraft.categoryNameAr).toBe(category.nameAr);
  });
});
