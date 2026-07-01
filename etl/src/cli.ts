import { Command } from "commander";
import { promises as fs } from "fs";
import path from "path";
import { getMssqlPool, closeMssql } from "./lib/mssql";
import { tryDecompress, parseDbNames, joinWithMetadata } from "./decode-dbnames";

const program = new Command();
program.name("pharma-dwh-etl").description("1C/MSSQL → Postgres DWH alət dəsti (PoC)");

// ---------------------------------------------------------------------------
// discover — discovery-sql/*.sql skriptlərini KOPYA bazada işlədir,
// nəticələri out/discovery/*.json yazır (Gate 1 hesabatının xammalı).
// ---------------------------------------------------------------------------
program
  .command("discover")
  .description("Bərpa olunmuş kopyada kəşfiyyat skriptlərini işlət")
  .action(async () => {
    const sqlDir = path.resolve(__dirname, "../../discovery-sql");
    const outDir = path.resolve(__dirname, "../out/discovery");
    await fs.mkdir(outDir, { recursive: true });

    const files = (await fs.readdir(sqlDir)).filter((f) => f.endsWith(".sql")).sort();
    const pool = await getMssqlPool();

    for (const file of files) {
      const sqlText = await fs.readFile(path.join(sqlDir, file), "utf8");
      process.stdout.write(`→ ${file} ... `);
      try {
        const result = await pool.request().batch(sqlText);
        const recordsets = Array.isArray(result.recordsets)
          ? result.recordsets
          : [result.recordset].filter(Boolean);
        const out = { file, ranAt: new Date().toISOString(), recordsets };
        await fs.writeFile(
          path.join(outDir, file.replace(/\.sql$/, ".json")),
          JSON.stringify(out, jsonSafe, 2),
          "utf8"
        );
        console.log(`OK (${recordsets.length} recordset)`);
      } catch (e) {
        console.log(`XƏTA: ${(e as Error).message}`);
        await fs.writeFile(
          path.join(outDir, file.replace(/\.sql$/, ".error.txt")),
          String((e as Error).stack ?? e),
          "utf8"
        );
      }
    }
    await closeMssql();
    console.log(`\nNəticələr: ${outDir}`);
  });

// ---------------------------------------------------------------------------
// decode-dbnames — Params.DBNames blob-unu açır (fayldan və ya birbaşa bazadan)
// ---------------------------------------------------------------------------
program
  .command("decode-dbnames")
  .description("1C DBNames xəritəsini aç (uuid ↔ _Document123 və s.)")
  .option("--file <path>", "SSMS-dən export olunmuş binary fayl (yoxdursa bazadan oxunur)")
  .option("--meta <path>", "обработка-nın metadata-dump.txt faylı (biznes adları üçün)")
  .action(async (opts: { file?: string; meta?: string }) => {
    let blob: Buffer;
    if (opts.file) {
      blob = await fs.readFile(opts.file);
    } else {
      const pool = await getMssqlPool();
      const rs = await pool
        .request()
        .query("SELECT BinaryData FROM dbo.Params WHERE FileName = N'DBNames'");
      await closeMssql();
      if (!rs.recordset.length) throw new Error("Params cədvəlində DBNames tapılmadı");
      blob = rs.recordset[0].BinaryData as Buffer;
    }

    const text = tryDecompress(blob);
    let entries = parseDbNames(text);
    if (opts.meta) {
      const metaDump = await fs.readFile(opts.meta, "utf8");
      entries = joinWithMetadata(entries, metaDump);
    }

    const outDir = path.resolve(__dirname, "../out");
    await fs.mkdir(outDir, { recursive: true });
    await fs.writeFile(path.join(outDir, "dbnames.json"), JSON.stringify(entries, null, 2), "utf8");
    const tsv = entries
      .map((e) =>
        [e.uuid, e.kind, e.num, e.table ?? "", (e as any).objectName ?? "", (e as any).synonym ?? ""].join("\t")
      )
      .join("\n");
    await fs.writeFile(path.join(outDir, "dbnames.tsv"), "uuid\tkind\tnum\ttable\tobject\tsynonym\n" + tsv, "utf8");
    console.log(`Açıldı: ${entries.length} qeyd → out/dbnames.json, out/dbnames.tsv`);
  });

// ---------------------------------------------------------------------------
// Phase 1/2 stub-ları — Gate 1 qərarlarından (maya branch-ı, cədvəl xəritəsi)
// asılı olduğundan hələ implement OLUNMAYIB. Bax: docs/plan.md → Phase 2/3.
// ---------------------------------------------------------------------------
for (const [name, phase] of [
  ["extract", "Phase 2"],
  ["transform", "Phase 2"],
  ["reconcile", "Phase 2"],
] as const) {
  program
    .command(name)
    .description(`[${phase}] Gate 1-dən sonra implement olunur`)
    .action(() => {
      console.error(
        `'${name}' hələ hazır deyil — ${phase} işidir və Gate 1 discovery nəticələrini ` +
        `(cədvəl xəritəsi + maya branch-ı) gözləyir. Bax: docs/plan.md`
      );
      process.exit(2);
    });
}

function jsonSafe(_key: string, value: unknown): unknown {
  if (Buffer.isBuffer(value)) return "0x" + value.toString("hex");
  if (typeof value === "bigint") return value.toString();
  return value;
}

program.parseAsync().catch((e) => {
  console.error(e);
  process.exit(1);
});
