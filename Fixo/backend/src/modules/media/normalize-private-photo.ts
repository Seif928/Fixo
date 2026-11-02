import { BadRequestException } from '@nestjs/common';
const sharp: typeof import('sharp').default = require('sharp');

/** Decode and re-encode private photos; strip metadata and bound allocation/output. */
export async function normalizePrivatePhoto(
  input: Buffer,
  mimeType: string,
  variant: 'avatar' | 'document' | 'booking',
): Promise<Buffer> {
  const formats: Record<string, string> = {
    'image/jpeg': 'jpeg',
    'image/png': 'png',
    'image/webp': 'webp',
  };
  if (!input?.length || input.length > 2 * 1024 * 1024 || !formats[mimeType]) {
    throw new BadRequestException(
      'Choose a JPEG, PNG or WebP photo up to 2 MB.',
    );
  }
  try {
    const image = sharp(input, {
      limitInputPixels: 20_000_000,
      failOn: 'warning',
    });
    const metadata = await image.metadata();
    if (metadata.format !== formats[mimeType] || (metadata.pages ?? 1) !== 1) {
      throw new Error('Invalid photo format');
    }
    const square = variant === 'avatar';
    const bytes = await image
      .rotate()
      .resize({
        width: square ? 256 : 1600,
        height: square ? 256 : 1600,
        fit: square ? 'cover' : 'inside',
        withoutEnlargement: !square,
      })
      .webp({ quality: square ? 82 : 88 })
      .toBuffer();
    if (bytes.length > 2 * 1024 * 1024)
      throw new Error('Photo exceeds output limit');
    return bytes;
  } catch {
    throw new BadRequestException(
      'The photo could not be read. Choose another JPEG, PNG or WebP photo.',
    );
  }
}
