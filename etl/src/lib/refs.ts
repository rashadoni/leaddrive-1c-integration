// 1C _IDRRef konvensiyaları — dim key=0 "Naməlum" üzvü ilə MƏCBURİ müqavilə.
// dwh/ddl/001-schema.sql seed blokuna bax: Phase 2 transform boş/unmapped ref-i
// UNKNOWN_KEY-ə map ETMƏLİDİR, əks halda mart view-larının inner JOIN-ları
// naməlum-ref sətirləri itirər və rekonsiliasiya pozular (architect 2026-06-11).

export const EMPTY_REF = "0".repeat(32); // 1C boş ref = 16 sıfır bayt → 32 hex sıfır

export const UNKNOWN_KEY = 0; // bütün dim-lərdə key=0 'Naməlum' üzvü (DDL seed)

export function refToHex(buf: Buffer): string {
  return buf.toString("hex");
}

export function isEmptyRef(hexRef: string | null | undefined): boolean {
  return !hexRef || hexRef === EMPTY_REF;
}

// Phase 2 transform-da dim lookup üçün: tapılmayan/boş ref → UNKNOWN_KEY
export function dimKeyOrUnknown(
  hexRef: string | null | undefined,
  lookup: Map<string, number>
): number {
  if (isEmptyRef(hexRef)) return UNKNOWN_KEY;
  return lookup.get(hexRef as string) ?? UNKNOWN_KEY;
}
