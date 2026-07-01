// DBNames decoder smoke-testi: sintetik blob → decompress → parse → assert.
// İşlətmək: npm run smoke
import { deflateRawSync } from "zlib";
import { tryDecompress, parseDbNames, joinWithMetadata } from "./decode-dbnames";
import assert from "assert";

const sample = `{4,
{"a1b2c3d4-0000-1111-2222-333344445555","Document",123},
{"b2c3d4e5-0000-1111-2222-333344445556","Reference",45},
{"c3d4e5f6-0000-1111-2222-333344445557","AccumRg",7001},
{"d4e5f6a7-0000-1111-2222-333344445558","VT",456}}`;

// 1) raw deflate (ən çox rast gəlinən hal)
const compressed = deflateRawSync(Buffer.from(sample, "utf8"));
const text = tryDecompress(compressed);
assert(text.includes('"Document"') || text.includes('"Document",123') || text.includes("Document"), "decompress failed");

// 2) parse
const entries = parseDbNames(text);
assert.strictEqual(entries.length, 4, `4 qeyd gözlənilirdi, ${entries.length} gəldi`);
assert.strictEqual(entries[0].table, "_Document123");
assert.strictEqual(entries[1].table, "_Reference45");
assert.strictEqual(entries[2].table, "_AccumRg7001");
assert.strictEqual(entries[3].kind, "VT");
assert.strictEqual(entries[3].table, null);

// 3) header offset dözümlülüyü (bəzi sürümlərdə blob başına bayt(lar) əlavə olunur)
const withHeader = Buffer.concat([Buffer.from([0x00, 0x01]), compressed]);
const text2 = tryDecompress(withHeader);
assert.strictEqual(parseDbNames(text2).length, 4, "offset-li blob açılmadı");

// 4) metadata join
const metaDump = [
  "#HEADER|version=1",
  "#META|Document|РеализацияТоваровУслуг|Реализация товаров и услуг|a1b2c3d4-0000-1111-2222-333344445555",
].join("\n");
const joined = joinWithMetadata(entries, metaDump);
assert.strictEqual((joined[0] as any).objectName, "РеализацияТоваровУслуг");

// 5) sıxılmamış blob halı
const plainText = tryDecompress(Buffer.from(sample, "utf8"));
assert.strictEqual(parseDbNames(plainText).length, 4);

// 6) refs konvensiyası (dim key=0 müqaviləsi — DDL seed bloku ilə cüt işləyir)
import { EMPTY_REF, UNKNOWN_KEY, isEmptyRef, dimKeyOrUnknown } from "./lib/refs";
assert.strictEqual(EMPTY_REF.length, 32);
assert.ok(isEmptyRef(EMPTY_REF) && isEmptyRef(null) && !isEmptyRef("ab12" + "0".repeat(28)));
const lookup = new Map([["ab12" + "0".repeat(28), 7]]);
assert.strictEqual(dimKeyOrUnknown("ab12" + "0".repeat(28), lookup), 7);
assert.strictEqual(dimKeyOrUnknown(EMPTY_REF, lookup), UNKNOWN_KEY);
assert.strictEqual(dimKeyOrUnknown("ff".repeat(16), lookup), UNKNOWN_KEY); // unmapped → 0

console.log("SMOKE OK — decoder: deflate ✓ offset ✓ parse(4) ✓ VT ✓ meta-join ✓ plain ✓ refs ✓");
