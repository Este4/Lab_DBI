const fs=require('fs'),path=require('path'),assert=require('assert/strict');
const {Client}=require('../../flow_tests_20261105/runtime/node_modules/pg');
const m=require('./live-manifest.json'),root=__dirname;
const c=new Client({host:'127.0.0.1',port:55443,user:'live_test',database:'postgres',statement_timeout:15000});
const results=[],outputs={};
const q=(s,p=[])=>c.query(s,p);
const file=f=>q(fs.readFileSync(path.join(root,f),'utf8'));
async function test(name,fn){const actual=await fn();results.push({name,status:'PASS',actual});console.log('PASS '+name);}
async function main(){
 await c.connect();
 await test('Cai schema rieng',async()=>{await file('00_setup_demo.sql');assert.equal((await q("SELECT count(*)::int n FROM information_schema.tables WHERE table_schema='dbi202_live'")).rows[0].n,17);assert.equal((await q(m.queries.META))[1].rows[0].user_trigger_count,'0');return '17 bang, 0 user trigger';});
 await test('INSERT cha truoc con',async()=>{await file('01_insert_theo_tang.sql');assert.equal((await q('SELECT count(*)::int n FROM order_line')).rows[0].n,6);return '4 don,6 dong,4 cap ton va4 ledger nhap';});
 for(const id of ['Q1','Q2','Q3','Q4'])await test(id,async()=>{
  const rows=(await q(m.queries[id])).rows;outputs[id]=rows;
  if(id==='Q1'){assert.equal(rows.length,2);assert.deepEqual(rows.map(x=>Number(x.line_total)),[50000,40000]);}
  if(id==='Q2')assert.deepEqual(rows.map(x=>Number(x.goods_total)),[90000,990000,20000,40000]);
  if(id==='Q3')assert.deepEqual(rows.map(x=>Number(x.order_count)),[3,1]);
  if(id==='Q4')assert.deepEqual(rows.map(x=>x.available_qty),[10,3,6,5]);
  return rows;
 });
 for(const x of m.bad)await test(x.id+' '+x.name,async()=>{
  await q('BEGIN;SET LOCAL search_path TO dbi202_live');let e;
  try{await q(x.sql);}catch(error){e=error;}finally{await q('ROLLBACK');}
  assert.ok(e,'Can bao loi');assert.equal(e.code,x.code);
  if(x.constraint)assert.equal(e.constraint,x.constraint);
  if(x.column)assert.equal(e.column,x.column);
  return {code:e.code,constraint:e.constraint||null,message:e.message};
 });
 await test('Giu hang',async()=>{await file('02_reserve.sql');return 'Sach10/giu5; ly3/giu2';});
 await test('Dong goi va duyet',async()=>{await file('03_pack_and_approve.sql');return 'Hai kien APPROVED, don PACKED';});
 await test('Trigger minh hoa va rollback',async()=>{
  await q(m.triggerSetup);let e;
  try{await q(m.triggerBad);}catch(error){e=error;}finally{await q('ROLLBACK');}
  assert.ok(e);assert.equal(e.code,'23514');assert.ok(e.message.startsWith('TRIGGER DEMO:'));
  const r=await q("SELECT count(*)::int n FROM pg_trigger t JOIN pg_class c ON c.oid=t.tgrelid WHERE c.relnamespace='dbi202_live'::regnamespace AND NOT t.tgisinternal");assert.equal(r.rows[0].n,0);
  return {message:e.message,userTriggersAfter:0};
 });
 await test('Ban giao',async()=>{await file('04_handover.sql');return 'Sach5/giu0; ly1/giu0; don SHIPPED';});
 await test('Giao thanh cong',async()=>{await file('05_deliver.sql');return 'Don DELIVERED';});
 for(const id of ['Q5','Q6','Q7'])await test(id,async()=>{
  const rows=(await q(m.queries[id])).rows;outputs[id]=rows;
  if(id==='Q5')assert.deepEqual(rows.map(x=>Number(x.packaging_cost)),[4900,3100]);
  if(id==='Q6')assert.ok(rows.length===4&&rows.every(x=>x.balanced));
  if(id==='Q7'){assert.equal(Number(rows[0].delivered_order_count),1);assert.equal(Number(rows[0].delivered_goods_value),90000);}
  return rows;
 });
 fs.writeFileSync(path.join(root,'VERIFIED_LIVE.json'),JSON.stringify({date:'2026-11-05',version:(await q('SELECT version() v')).rows[0].v,results,outputs},null,2));
 console.log('TOTAL '+results.length+' PASS');
}
main().catch(e=>{console.error(e);process.exitCode=1}).finally(()=>c.end());
