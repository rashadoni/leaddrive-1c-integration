// ============================================================================
// DBNames decoder — 1C SQL bazasının `Params` cədvəlindəki `DBNames` qeydini açır:
// metadata obyekt UUID-ləri ↔ SQL cədvəl növü+nömrəsi (_Document123 və s.).
// Bu, ПолучитьСтруктуруХраненияБазыДанных() 8.2-də əlçatmaz olduqda əsas fallback-dır.
//
// Blob deflate ilə sıxılıb; başlıq sürümə görə dəyişə bildiyindən decoder bir neçə
// offset/alqoritm kombinasiyasını sınayır və '{'-la başlayan mətni qəbul edir.
// ============================================================================

import { inflateRawSync, inflateSync } from "zlib";

export interface DbNameEntry {
  uuid: string;
  kind: string;        // Document | Reference | AccumRg | VT | ...
  num: number;
  table: string | null; // _Document123; VT üçün null (valideynlə birləşir)
  note?: string;
}

const KIND_PREFIX: Record<string, string> = {
  Document: "_Document",
  Reference: "_Reference",
  Enum: "_Enum",
  Const: "_Const",
  InfoRg: "_InfoRg",
  AccumRg: "_AccumRg",
  AccumRgT: "_AccumRgT",
  AccRg: "_AccRg",
  Chrc: "_Chrc",
  Node: "_Node",
  DocumentJournal: "_DocJournal",
  Sequence: "_Seq",
};

export function tryDecompress(buf: Buffer): string {
  const attempts: Array<() => Buffer> = [];
  for (const off of [0, 1, 2, 4, 8, 16]) {
    attempts.push(() => inflateRawSync(buf.subarray(off)));
    attempts.push(() => inflateSync(buf.subarray(off)));
  }
  for (const attempt of attempts) {
    try {
      const out = attempt();
      const text = out.toString("utf8");
      if (text.trimStart().startsWith("{")) return text;
    } catch {
      /* növbəti kombinasiya */
    }
  }
  // Bəzi sürümlərdə blob ümumiyyətlə sıxılmamış olur
  const plain = buf.toString("utf8");
  if (plain.trimStart().startsWith("{")) return plain;
  throw new Error(
    "DBNames blob-u açıla bilmədi: nə raw-deflate, nə zlib, nə düz mətn. " +
    "Blob-un ilk 32 baytını bizə göndərin (hex)."
  );
}

export function parseDbNames(text: string): DbNameEntry[] {
  // Sətir formatı (tipik): {"<uuid>","Kind",<num>}
  const re = /\{"([0-9a-fA-F-]{36})",\s*"?([A-Za-z]+)"?,\s*(\d+)\}/g;
  const entries: DbNameEntry[] = [];
  let m: RegExpExecArray | null;
  while ((m = re.exec(text)) !== null) {
    const kind = m[2];
    const num = Number(m[3]);
    const prefix = KIND_PREFIX[kind];
    entries.push({
      uuid: m[1].toLowerCase(),
      kind,
      num,
      table: kind === "VT" ? null : prefix ? `${prefix}${num}` : null,
      note:
        kind === "VT"
          ? `tabular section: valideyn cədvəl adı + _VT${num}`
          : prefix
          ? undefined
          : `naməlum kind — xəritəyə əl ilə baxılmalı`,
    });
  }
  return entries;
}

// metadata-dump.txt (#META|Kind|Name|Synonym|UUID) ilə birləşdirmə —
// UUID обработка-da çıxarıla bilibsə biznes adları cədvəllərə bağlanır.
export function joinWithMetadata(
  entries: DbNameEntry[],
  metaDump: string
): Array<DbNameEntry & { objectName?: string; synonym?: string }> {
  const byUuid = new Map<string, { name: string; synonym: string }>();
  for (const line of metaDump.split(/\r?\n/)) {
    if (!line.startsWith("#META|")) continue;
    const parts = line.split("|");
    const uuid = (parts[4] ?? "").trim().toLowerCase();
    if (uuid) byUuid.set(uuid, { name: parts[2], synonym: parts[3] });
  }
  return entries.map((e) => {
    const meta = byUuid.get(e.uuid);
    return meta ? { ...e, objectName: meta.name, synonym: meta.synonym } : e;
  });
}
