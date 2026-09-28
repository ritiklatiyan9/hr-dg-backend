// Synthetic browser/emulator environment only. No production URLs or payroll data.
import {pool} from '../packages/db/src/index.js';
import {migrate} from '../packages/db/src/migrate.js';
import {ids} from '../packages/db/src/seed.js';
import {permissionKeys} from '../packages/authz/src/catalogue.js';
const url=process.env.MIGRATION_DATABASE_URL!;
if(new URL(url).pathname!='/hr_local'||!['localhost','127.0.0.1'].includes(new URL(url).hostname))throw Error('Synthetic localhost hr_local database required');
await migrate(url);
const db=pool(url,1);
try{
 for(const user of [ids.admin,ids.siteAdmin,ids.superAdmin])for(const key of permissionKeys.filter(k=>['payroll','expenses','assets','helpdesk','announcements','documents'].includes(k.split('.')[0]!)))await db.query("INSERT INTO app.access_overrides(organization_id,site_id,user_id,key,effect,scope) VALUES($1,$2,$3,$4,'allow','site') ON CONFLICT(organization_id,site_id,user_id,key) DO UPDATE SET effect='allow',scope='site'",[ids.org,ids.dg,user,key]);
 for(const key of ['grievances.view','grievances.review','grievances.manage','grievances.field.confidential'])await db.query("INSERT INTO app.access_overrides(organization_id,site_id,user_id,key,effect,scope) VALUES($1,$2,$3,$4,'allow','site') ON CONFLICT(organization_id,site_id,user_id,key) DO UPDATE SET effect='allow',scope='site'",[ids.org,ids.dg,ids.admin,key]);
 await db.query('INSERT INTO app.hr_case_handlers VALUES($1,$2,$3) ON CONFLICT DO NOTHING',[ids.org,ids.dg,ids.admin]);
 console.log('Phase 5 synthetic local migrations and explicit fixture grants ready.');
}finally{await db.end();}
