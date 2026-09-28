/** A verified upload intent witnesses a timely online capture while its bytes
 * travel through storage. Old/offline captures still need independent review. */
export function onlineEvidenceTimely(
  captureAt: number,
  receivedAt: number,
  photoIntentAt: number | null,
  freshnessSeconds: number,
): boolean {
  if (receivedAt - captureAt <= freshnessSeconds * 1000) return true;
  return (
    photoIntentAt !== null &&
    Math.abs(photoIntentAt - captureAt) <= freshnessSeconds * 1000 &&
    receivedAt >= photoIntentAt &&
    receivedAt - photoIntentAt <= 5 * 60 * 1000
  );
}
