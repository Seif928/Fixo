import { cairoBookingTime } from "./cairo-booking-time";
describe("Cairo appointment time", () => {
  it("converts winter wall time", () =>
    expect(cairoBookingTime("2026-11-15", "23:45").toISOString()).toBe(
      "2026-11-15T21:45:00.000Z",
    ));
  it("converts summer wall time", () =>
    expect(cairoBookingTime("2026-07-15", "00:15").toISOString()).toBe(
      "2026-07-14T21:15:00.000Z",
    ));
  it.each(["24:00", "12:60", "1:20"])("rejects invalid time %s", (value) =>
    expect(() => cairoBookingTime("2026-11-15", value)).toThrow(),
  );
});
