import { BadRequestException } from "@nestjs/common";

/** Convert a Cairo wall-clock appointment to a UTC instant, including DST. */
export function cairoBookingTime(date: string, time: string): Date {
  if (
    !/^\d{4}-\d{2}-\d{2}$/.test(date) ||
    !/^([01]\d|2[0-3]):[0-5]\d$/.test(time)
  )
    throw new BadRequestException("Invalid appointment date or time.");
  const wall = `${date}T${time}:00`;
  const formatter = new Intl.DateTimeFormat("sv-SE", {
    timeZone: "Africa/Cairo",
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
    hour: "2-digit",
    minute: "2-digit",
    hourCycle: "h23",
  });
  const matches = [2, 3]
    .map((offset) => new Date(Date.parse(wall + "Z") - offset * 3600000))
    .filter(
      (value) =>
        formatter.format(value).replace(" ", "T") === wall.slice(0, 16),
    );
  if (matches.length !== 1)
    throw new BadRequestException(
      "Choose another time near the daylight-saving transition.",
    );
  return matches[0];
}

export function cairoBookingDate(value:Date|string):string {
 return new Intl.DateTimeFormat('sv-SE',{timeZone:'Africa/Cairo',year:'numeric',month:'2-digit',day:'2-digit'}).format(new Date(value));
}
