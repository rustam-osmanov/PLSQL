----2
Select USR.USER_ID,USR.NAME from SUPPORT_PSS.A_USERS USR
  left JOIN SUPPORT_PSS.A_ORDERS ORD on ORD.USER_ID= USR.USER_ID  
  where ORD.STATUS=0;
  
  
 Select USR.USER_ID,USR.NAME from SUPPORT_PSS.A_USERS USR 
  where USR.USER_ID in 
             (SELECT  USER_ID from SUPPORT_PSS.A_ORDERS ORD where ORD.STATUS=1
               group by USER_ID
               having count(USER_ID)>5); 
  
   Select USR.USER_ID,USR.NAME from SUPPORT_PSS.A_USERS USR 
    where exists (select GRP.USER_ID from 
                  (SELECT  USER_ID from SUPPORT_PSS.A_ORDERS ORD where ORD.STATUS=1
                   group by USER_ID
                   having count(USER_ID)>5
                )GRP where GRP.USER_ID=USR.USER_ID ); 
  
----3  
  Select T1.ID,T1.DT from SUPPORT_PSS.A_T1 T1 
  where T1.ID in
  (SELECT  MAX(ID) from SUPPORT_PSS.A_T1 ) ;
  
--4
Select  DT.DT , T1.cntT1, T2.cntT2   from 
( Select DISTINCT TO_CHAR(A_T1.DT,'dd.mm.yyyy') DT from SUPPORT_PSS.A_T1
    UNION 
  Select DISTINCT TO_CHAR(A_T2.DT,'dd.mm.yyyy') DT from SUPPORT_PSS.A_T2) DT
  left join (Select TO_CHAR(T1.DT,'dd.mm.yyyy') as DT,count(T1.ID) as cntT1
                from SUPPORT_PSS.A_T1 T1
                group by TO_CHAR(T1.DT,'dd.mm.yyyy') ) T1 on T1.DT = DT.DT   
  left join (Select TO_CHAR(T2.DT,'dd.mm.yyyy') as DT,count(T2.ID) as cntT2
                from SUPPORT_PSS.A_T2 T2
                group by TO_CHAR(T2.DT,'dd.mm.yyyy') ) T2 on T2.DT = DT.DT 
order by DT.DT ;
---5
Select TO_CHAR(A_PHONE.DT,'dd.mm.yyyy') DT ,client,phonenum,call_duration
from SUPPORT_PSS.A_PHONE
where exists (select GRP.USER_ID from 
                  (SELECT  USER_ID from SUPPORT_PSS.A_ORDERS ORD where ORD.STATUS=1
                   group by USER_ID
                   having count(USER_ID)>5
                )GRP where GRP.USER_ID=USR.USER_ID ); 
--listagg( last_num,';' ) within group (order by DT,client) as client
Select DT
       ,client
       ,max(last_num) last_num
       ,max(phonenum) phonenum
       ,max(maxCL_call_duration) call_duration
       ,max(maxDT_call_duration) max_call_duration
from (
   Select  client,phonenum,call_duration,
    LAST_VALUE(phonenum) over (partition by client,TO_CHAR(A_PHONE.DT,'dd.mm.yyyy') ) as last_num,
    max(call_duration) over (partition by client, TO_CHAR(A_PHONE.DT,'dd.mm.yyyy') ) as maxCL_call_duration ,
    max(call_duration) over (partition by  TO_CHAR(A_PHONE.DT,'dd.mm.yyyy') ) as maxDT_call_duration ,
    TO_CHAR(A_PHONE.DT,'dd.mm.yyyy') DT
    from SUPPORT_PSS.A_PHONE 
    ) MAXCLIENT
group by DT,client
order by DT,client
;
----6
WITH
   MaxClient AS
    (
        Select max(rn) as mxrn,CLIENT_ID from 
     (
         Select row_number() over (partition by CLIENT_ID order by CLIENT_ID,START_DATETIME) as rn ,
         CLIENT_ID,CREDIT_ID,CREDIT_PURPOSE,DEBT_SUMM,START_DATETIME 
         from SUPPORT_PSS.A_CREDIT 
         where DEBT_SUMM> 10000 and START_DATETIME is not null
       )
      group by  CLIENT_ID
    )
Select grp.* from (
Select row_number() over (partition by CLIENT_ID order by CLIENT_ID,START_DATETIME) as rn ,
       CLIENT_ID,CREDIT_ID,CREDIT_PURPOSE,DEBT_SUMM,START_DATETIME 
from SUPPORT_PSS.A_CREDIT 
 where DEBT_SUMM> 10000 and START_DATETIME is not null) grp
 where mod(rn,4) = 0 or 
       (mod(rn, 3) =0 and   
        EXISTS ( Select CLIENT_ID FROM MaxClient where  maxclient.client_id = grp.client_id and mxrn<4)
         ) 
 ;
---7
Select CLIENT_ID,TYPE_PHONE,NUM_PHONE from (
Select CLIENT_ID,TYPE_PHONE,NUM_PHONE from (
Select 
row_number() over (partition by CLIENT_ID,TYPE_PHONE order by CLIENT_ID,TYPE_PHONE,in_datetime desc) as rn,
CLIENT_ID,TYPE_PHONE,NUM_PHONE
from SUPPORT_PSS.A_CLIENT_Z7 clnt
order by CLIENT_ID,TYPE_PHONE,in_datetime )
 where rn =1
) 
pivot (
 max(NUM_PHONE) 
 for TYPE_PHONE in ('mobile' as mobile, 'home' as home,'work' as work)
)
; 

---8
SELECT rts.CRNC,rts.TERM,rts.RATE,rts.DT as dt_start, min(rtslft.DT) as dt_end
from SUPPORT_PSS.A_RATES rts
 left join SUPPORT_PSS.A_RATES rtslft on rts.CRNC = rtslft.CRNC 
                                    and  rts.TERM = rtslft.TERM
                                    and  rts.DT < rtslft.DT
group by rts.CRNC,rts.TERM,rts.RATE,rts.DT 
order by rts.CRNC,rts.TERM,rts.RATE,rts.DT;
