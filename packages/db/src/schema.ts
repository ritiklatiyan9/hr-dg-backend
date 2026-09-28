import { pgSchema, uuid, text, integer, timestamp } from "drizzle-orm/pg-core";
const app = pgSchema("app");
// SQL migrations are authoritative for composite FKs, PostGIS and policies.
export const employees = app.table("employees", {
  id: uuid("id").primaryKey(),
  organizationId: uuid("organization_id").notNull(),
  userId: uuid("user_id"),
  employeeCode: text("employee_code").notNull(),
  displayName: text("display_name").notNull(),
  workEmail: text("work_email").notNull(),
  phone: text("phone").notNull(),
  jobTitle: text("job_title").notNull(),
  department: text("department").notNull(),
  version: integer("version").notNull(),
  createdAt: timestamp("created_at", { withTimezone: true }).notNull(),
  updatedAt: timestamp("updated_at", { withTimezone: true }).notNull(),
});
