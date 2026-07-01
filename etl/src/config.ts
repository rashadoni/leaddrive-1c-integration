import dotenv from "dotenv";

dotenv.config();

function required(name: string): string {
  const v = process.env[name];
  if (!v) throw new Error(`Env dəyişəni çatışmır: ${name} (bax: .env.example)`);
  return v;
}

export const config = {
  mssql: {
    get server() { return required("MSSQL_SERVER"); },
    get port() { return Number(process.env.MSSQL_PORT ?? 1433); },
    get database() { return required("MSSQL_DATABASE"); },
    get user() { return required("MSSQL_USER"); },
    get password() { return required("MSSQL_PASSWORD"); },
  },
  pg: {
    get host() { return process.env.PGHOST ?? "localhost"; },
    get port() { return Number(process.env.PGPORT ?? 5433); },
    get database() { return process.env.PGDATABASE ?? "pharma_dwh"; },
    get user() { return process.env.PGUSER ?? "dwh"; },
    get password() { return process.env.PGPASSWORD ?? "dwh_dev"; },
  },
};
