create table tariff_plans (
    tariff_plan_id number primary key,
    plan_name varchar2(50),
    monthly_fee number,
    free_minutes number,
    free_internet_mb number
);

create table subscribers (
    subscriber_id number primary key,
    full_name varchar2(100),
    gender varchar2(10),
    birth_date date,
    registiration_date date,
    tariff_plan_id number,
    city varchar2(50),
    status varchar2(20),
    constraint fk_sub_tariff
        foreign key (tariff_plan_id)
        references tariff_plans(tariff_plan_id)
);

create table call_data_records (
    record_id number primary key,
    subscriber_id number,
    activity_date date,
    activity_type varchar2(20),
    duration_min number,
    data_used_mb number,
    constraint fk_cdr_sub
        foreign key (subscriber_id)
        references subscribers(subscriber_id)
);

create table billing_history (
    invoice_id number   primary key,
    subscriber_id number,
    bill_date date,
    amount_charged number,
    amount_paid number,
    payment_status varchar2(20),
    constraint fk_bill_sub
        foreign key (subscriber_id)
        references subscribers(subscriber_id)
);

select count(*) from tariff_plans;
select count(*) from subscribers;
select count(*) from call_data_records;
select count(*) from billing_history;

select * from billing_history;
select * from call_data_records;
select * from subscribers;
select * from tariff_plans;

--I. Abunəçi Profil Analizi (Demographics & Cleanup)

/*1.	Mətn manipulyasiyası: Hər bir abunəçinin adını və soyadını fərqli sətir funksiyaları ilə manipulyasiya edin
(Məsələn, adın ilk hərfi, soyad tam böyük hərflərlə) və yanına LENGTH funksiyası ilə tam adın uzunluğunu çıxarın.*/
select
    subscriber_id,
    full_name,
    substr(full_name, 1, 1) as first_letter,
    upper(substr(full_name, instr(full_name, ' ') + 1)) as upper_last_name, 
    length(full_name) as name_length
from subscribers
order by subscriber_id;

--2.	Coğrafi paylanma: Hər şəhər üzrə neçə abunəçi olduğunu və onların status paylanmasını (Active, Churned) göstərən dinamik hesabat hazırlayın
select
    city,
    count(subscriber_id) as subscriber_count,
    sum(case 
            when lower(status) = 'active' 
            then 1
            else 0 
        end) as active,
    sum(case 
            when lower(status) = 'suspended' 
            then 1 
            else 0 
        end) as suspended,
    sum(case
            when lower(status) = 'churned' 
            then 1 
            else 0 
        end) as churned
from subscribers
group by city
order by subscriber_count desc;

/* 3.	Yaş seqmentasiyası: Abunəçilərin yaşını MONTHS_BETWEEN və ya SYSDATE vasitəsilə hesablayın və
CASE WHEN funksiyası ilə onları yaş qruplarına bölün ('Gənc' < 25, 'Orta Yaş' 25-50, 'Senior' > 50). */
select 
    subscriber_id, 
    full_name,
    case
        when subscriber_age < 25 then 'genc'
        when subscriber_age < 50 then 'orta yas'
        else 'senior'
    end as age_category
from (
select 
    subscriber_id,
    full_name,
    trunc(months_between(sysdate, birth_date)/12, 0) as subscriber_age
from subscribers
);

--hər yaş qrupunun sayını göstərən(excel üçün)
select 
    case
        when subscriber_age < 25 then 'genc'
        when subscriber_age < 50 then 'orta yas'
        else 'senior'
    end as age_category,
    count(*) as count
from (select 
        subscriber_id,
        full_name,
        trunc(months_between(sysdate, birth_date) / 12, 0) as subscriber_age
    from subscribers)
group by 
    case
        when subscriber_age < 25 then 'genc'
        when subscriber_age < 50 then 'orta yas'
        else 'senior'
    end
order by count desc;

--əlavələrim
--şirkət ildən ilə neçə yeni abunəçi qazanıb?
select 
    subscriber_id,
    registiration_date
from subscribers
order by registiration_date desc;   --asc və desc ilə yoxlayıb gördük ki 2021 yanvar ayindan 2025 decabr ayina kimidir

select
    to_char(registiration_date, 'YYYY') as registiration_year,
    count(subscriber_id) as musteri_sayi
from subscribers
group by to_char(registiration_date, 'YYYY')
order by registiration_year;

--Müştərilər orta hesabla neçə ildir bizimlədir (suspended, churned, active) 
select
    status,
    round(avg(months_between(sysdate, registiration_date) / 12), 1) as years_with_us
from subscribers
group by status
order by years_with_us desc;

--Hansı yaş qrupu şirkəti ən çox tərk edir (yaş qrupu üzrə churn faizi)
select
    case 
        when yas < 25 then 'genc'
        when yas < 50 then 'orta yasli'
        else 'senior'
    end as age_category,
    count(*) as umumi,
    sum(case when lower(status) = 'churned' then 1 else 0 end) as terk_eden,
    round(sum(case when lower(status) = 'churned' then 1 else 0 end) / count(*) * 100, 1) as churn_faizi
from (
    select status, trunc(months_between(sysdate, birth_date) / 12) as yas
    from subscribers
)
group by 
    case 
        when yas < 25 then 'genc'
        when yas < 50 then 'orta yasli'
        else 'senior'
    end;

--II. İstifadə Trafiki və Paket Analizi (Usage & Behavior)

/*1.	İstifadə xülasəsi: Hər abunəçinin ümumi etdiyi zənglərin sayını, cəmi danışıq dəqiqəsini (duration_min) və 
xərclədiyi internet meqabaytını (data_used_mb) çıxarın. */

select
    s.subscriber_id,
    s.full_name,
    count(case when lower(c.activity_type) = 'call' then 1 end) as call_count,
    nvl(sum(c.duration_min), 0) as overall_call_minute,
    nvl(sum(data_used_mb), 0) as used_mb
from subscribers s
left join call_data_records c 
    on s.subscriber_id = c.subscriber_id
group by s.subscriber_id, s.full_name
order by overall_call_minute desc, used_mb desc;


/* 2.	Passiv müştərilər: NVL və ya COALESCE istifadə edərək, heç bir şəbəkə aktivliyi (CDR) olmayan abunəçilərin 
qarşısına 'Aktivlik qeydə alınmayıb' yazdırın (LEFT JOIN istifadə edilməlidir).*/

select
    s.subscriber_id,
    s.full_name,
    nvl(to_char(max(c.activity_date),'YYYY.MM.DD'), 'Aktivlik qeyde alinmayib') as last_activity_date,
    count(c.record_id) as activation_count
from subscribers s
left join call_data_records c
    on s.subscriber_id = c.subscriber_id
group by s.subscriber_id, s.full_name;

/*3.	Limit aşımı: Hər abunəçinin öz tarif paketində verilən pulsuz dəqiqələri keçib-keçmədiyini yoxlayın.
Əgər keçibsə, neçə dəqiqə limitdən kənara çıxdığını hesablayın.*/
select
    s.subscriber_id,
    s.full_name,
    t.plan_name,
    t.free_minutes,
    nvl(sum(c.duration_min), 0) as used_min,
    case
        when t.free_minutes < nvl(sum(c.duration_min), 0) then nvl(sum(c.duration_min), 0) - t.free_minutes
        else 0
        end as limitden_kenar_veziyyeti
from tariff_plans t
join subscribers s
    on s.tariff_plan_id = t.tariff_plan_id
left join call_data_records c
    on c.subscriber_id = s.subscriber_id
    and c.activity_type = 'Call'
group by s.subscriber_id, s.full_name, t.plan_name, t.free_minutes
order by limitden_kenar_veziyyeti desc;

--Əlavələrim
--İnternet limit aşımı
select
    s.subscriber_id,
    s.full_name,
    t.plan_name,
    t.free_internet_mb,
    sum(c.data_used_mb) as used_mb,
    case
        when sum(nvl(c.data_used_mb, 0)) > t.free_internet_mb then sum(nvl(c.data_used_mb,0)) - t.free_internet_mb
        else 0 
    end as limitden_kenar_mb
from subscribers s
join call_data_records c
    on s.subscriber_id = c.subscriber_id
join tariff_plans t
    on s.tariff_plan_id = t.tariff_plan_id
group by s.subscriber_id, s.full_name, t.plan_name, t.free_internet_mb, t.free_internet_mb
order by limitden_kenar_mb desc;
    

--III. Maliyyə və Ödəniş İntizamı Analizi (Billing & Revenue)

--1.	Gəlirli tariflər: Şirkətin ən çox gəlir əldə etdiyi tarif planlarını azalan sıra ilə sıralayın (SUM(amount_charged)).

select 
    t.tariff_plan_id,
    t.plan_name,
    sum(b.amount_charged) as plan_charge
from billing_history b
join subscribers s
    on b.subscriber_id = s.subscriber_id
join tariff_plans t
    on s.tariff_plan_id = t.tariff_plan_id
group by t.tariff_plan_id, t.plan_name
order by plan_charge desc
fetch first 1 rows only;


/*2.	Borc analizi: Ödəniş statusu 'Unpaid' (Ödənilməyən) və 'Late Paid' (Gecikdirilən) 
olan fakturaların ümumi məbləğini tapın və hər müştərinin şirkətə olan ümumi borcunu hesablayın.*/
select 
    s.subscriber_id,
    s.full_name,
    sum(b.amount_charged) as umumi_borc
from billing_history b
join subscribers s
    on s.subscriber_id = b.subscriber_id
where lower(b.payment_status) in ('unpaid','late_paid')
group by s.subscriber_id, s.full_name
order by umumi_borc desc;

/*3.	Lokallaşdırma: DECODE və ya CASE WHEN funksiyası ilə ödəniş statuslarını lokallaşdırın 
('Paid' -> 'Tam Ödənilib', 'Unpaid' -> 'Borcu Var', 'Late Paid' -> 'Gecikmə ilə ödənilib').*/
select 
    invoice_id,
    subscriber_id,
    bill_date,
    amount_charged,
    payment_status,
    case
        when lower(payment_status) = 'paid' then 'Tam odenilib'
        when lower(payment_status) = 'unpaid' then 'Borcu var'
        when lower(payment_status) = 'late paid' then 'Gecikme ile odenilib'
    end as odenis_statusu
from billing_history
order by bill_date desc, subscriber_id ;

--Excel üçün ödəniş statuslarının paylanması
select 
    count(subscriber_id) as faktura_sayı,
    case
        when lower(payment_status) = 'paid' then 'Tam odenilib'
        when lower(payment_status) = 'unpaid' then 'Borcu var'
        when lower(payment_status) = 'late paid' then 'Gecikme ile odenilib'
    end as odenis_statusu
from billing_history
group by 
    case
        when lower(payment_status) = 'paid' then 'Tam odenilib'
        when lower(payment_status) = 'unpaid' then 'Borcu var'
        when lower(payment_status) = 'late paid' then 'Gecikme ile odenilib'
    end;
        
        
--IV. CHURN (Müştəri İtkisi) Riski və Biznes İnsaytları (Yekun Hesabat)
/*•	Ən Kritik Analitik Sual: Son 3 ayda heç bir zəng etməyən və ya internet istifadə etməyən,
eyni zamanda son fakturasını ödənişsiz buraxan müştəriləri tapın.
Bu müştəriləri bazadakı status sütunundan asılı olmayaraq CASE WHEN ilə 'Yüksək Riskli (Churn Risk)' olaraq etiketləyin
və marketinq şöbəsi üçün əlaqə nömrələri (və ya adları) və yaşadıqları şəhərlə birgə siyahılayın.*/

--Son  3 ayda hec olmasa bir defe aktivlik gosterenler
select distinct subscriber_id
from call_data_records
where months_between(sysdate, activity_date) <=3;

-- Hər kəsin son fakturası
select subscriber_id, payment_status, bill_date
from (
    select
        subscriber_id,
        payment_status,
        bill_date,
        row_number() over (partition by subscriber_id 
                           order by bill_date desc) as rn
    from billing_history
)
where rn = 1;

--son 3 ayda aktiv olmayan və son fakturası unpaid olan müştərilər
with t1 as (
select
    s.subscriber_id,
    s.full_name,
    s.city,
    s.status,
    case
        when s.subscriber_id not in (
                select distinct subscriber_id
                from call_data_records
                where months_between(sysdate, activity_date) <=3)
         and lower(son_faktura.payment_status) = 'unpaid'
        then 'yüksək riskli (Churn)'
        else 'normal'
    end as risk
from subscribers s
left join (
    select subscriber_id, payment_status
    from (select subscriber_id, payment_status,
               row_number() over (partition by subscriber_id order by bill_date desc) as rn
         from billing_history)
    where rn = 1
) son_faktura on son_faktura.subscriber_id = s.subscriber_id
)
select * from t1
where lower(risk) in ('yüksək riskli (churn)');


--əlavələr (kpi lar):
select sum(amount_charged) as hesablanmis_gelir
from billing_history;

select
    sum(amount_paid) as yigilan_odenis
from billing_history;

select sum(amount_charged - NVL(amount_paid, 0)) as umumi_borc
from billing_history
where lower(payment_status) in ('unpaid', 'late paid');


--status paylanması
select
    status,
    count(*) as say
from subscribers
group by status
order by say desc;

--cins paylanması
select
    gender,
    count(*) as say
from subscribers
group by gender
order by say desc;








    
