/// Canonical route path constants for all 16 Stitch screens in the FIXO scope.
///
/// Do not add unapproved top-level routes outside the 16-screen handoff.
abstract final class AppRoutes {
  // Customer Flow (01–10)
  static const String onboarding = '/onboarding'; // 01_onboarding
  static const String phoneAuth = '/auth/phone'; // 02_phone_auth_otp
  static const String customerHome = '/customer/home'; // 03_customer_home
  static const String createBooking =
      '/customer/bookings/new'; // 04_create_booking
  static const String checkout =
      '/customer/bookings/:bookingId/checkout'; // 05_payment
  static const String orderTracking =
      '/customer/orders/:orderId/tracking'; // 06_live_order_tracking
  static const String customerChat =
      '/customer/orders/:orderId/chat'; // 07_customer_chat
  static const String myOrders = '/customer/orders'; // 08_my_orders
  static const String rateReview =
      '/customer/orders/:orderId/review'; // 09_rate_review
  static const String customerProfile =
      '/customer/profile'; // 10_profile_notifications

  // Professional Flow (11–16)
  static const String proSignUp =
      '/pro/onboarding/signup'; // 11_pro_sign_up_details
  static const String proSkills =
      '/pro/onboarding/skills'; // 12_services_skills
  static const String proVerificationDocs =
      '/pro/onboarding/documents'; // 13_id_licenses_upload
  static const String proVerificationStatus =
      '/pro/onboarding/status'; // 14_verification_status
  static const String proDashboard = '/pro/dashboard'; // 15_pro_dashboard
  static const String incomingJobRequest =
      '/pro/jobs/:jobId/incoming'; // 16_incoming_job_request
}
