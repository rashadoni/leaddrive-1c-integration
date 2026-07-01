import sql from "mssql";
import { config } from "../config";

let pool: sql.ConnectionPool | null = null;

// QEYD (plan: "1C 8.2 texniki tələləri"):
//  - useUTC:false — 1C tarixləri wall-clock saxlayır (AZ UTC+4, DST yox)
//  - pul sütunları real extract-da SQL tərəfində CONVERT(varchar, col) ilə
//    string kimi çəkilməlidir — JS float-a numeric(15,x) buraxmaq olmaz
//  - _IDRRef binary(16) → JS Buffer → hex (etl tərəfində .toString("hex"))
export async function getMssqlPool(): Promise<sql.ConnectionPool> {
  if (pool?.connected) return pool;
  pool = await new sql.ConnectionPool({
    server: config.mssql.server,
    port: config.mssql.port,
    database: config.mssql.database,
    user: config.mssql.user,
    password: config.mssql.password,
    requestTimeout: 600_000,
    connectionTimeout: 30_000,
    pool: { max: 4, min: 0 },
    options: {
      useUTC: false,
      encrypt: false,
      trustServerCertificate: true,
      enableArithAbort: true,
    },
  }).connect();
  return pool;
}

export async function closeMssql(): Promise<void> {
  if (pool) { await pool.close(); pool = null; }
}
