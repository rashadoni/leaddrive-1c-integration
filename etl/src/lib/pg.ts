import { Pool } from "pg";
import { config } from "../config";

let pool: Pool | null = null;

export function getPgPool(): Pool {
  if (!pool) {
    pool = new Pool({
      host: config.pg.host,
      port: config.pg.port,
      database: config.pg.database,
      user: config.pg.user,
      password: config.pg.password,
      max: 8,
    });
  }
  return pool;
}

// Aylıq partisiyanı (yoxdursa) yaradır — Phase 2 yükləmələrində hər fakt cədvəli üçün.
// Ad nümunəsi: dwh.fact_sales_line_2026_06
export async function ensureMonthPartition(parentTable: string, day: Date): Promise<void> {
  const y = day.getFullYear();
  const m = day.getMonth() + 1;
  const from = `${y}-${String(m).padStart(2, "0")}-01`;
  const next = m === 12 ? `${y + 1}-01-01` : `${y}-${String(m + 1).padStart(2, "0")}-01`;
  const suffix = `${y}_${String(m).padStart(2, "0")}`;
  const [schema, table] = parentTable.includes(".")
    ? parentTable.split(".")
    : ["dwh", parentTable];
  await getPgPool().query(
    `CREATE TABLE IF NOT EXISTS ${schema}.${table}_${suffix} ` +
    `PARTITION OF ${schema}.${table} FOR VALUES FROM ('${from}') TO ('${next}')`
  );
}

export async function closePg(): Promise<void> {
  if (pool) { await pool.end(); pool = null; }
}
