--=============== МОДУЛЬ 5. РАБОТА С POSTGRESQL =======================================
--= ПОМНИТЕ, ЧТО НЕОБХОДИМО УСТАНОВИТЬ ВЕРНОЕ СОЕДИНЕНИЕ И ВЫБРАТЬ СХЕМУ PUBLIC===========
SET search_path TO public;

--======== ОСНОВНАЯ ЧАСТЬ ==============

--ЗАДАНИЕ №1
--Сделайте запрос к таблице payment и с помощью оконных функций добавьте вычисляемые колонки согласно условиям:
--Пронумеруйте все платежи от 1 до N по дате платежа
--Пронумеруйте платежи для каждого покупателя, сортировка платежей должна быть по дате платежа
--Посчитайте нарастающим итогом сумму всех платежей для каждого покупателя, сортировка должна 
--быть сперва по дате платежа, а затем по размеру платежа от наименьшей к большей
--Пронумеруйте платежи для каждого покупателя по размеру платежа от наибольшего к
--меньшему так, чтобы платежи с одинаковым значением имели одинаковое значение номера.
--Можно составить на каждый пункт отдельный SQL-запрос, а можно объединить все колонки в одном запросе.
select
	*,
	row_number () over (
	order by payment_date) as numofdate,
	row_number () over (partition by customer_id
order by payment_date) as numofcustanddate,
	sum(amount) over (partition by customer_id order by payment_date, amount) as oversum,
	dense_rank() over (partition by customer_id order by amount desc) as rankofamount
from
	payment p 



--ЗАДАНИЕ №2
--С помощью оконной функции выведите для каждого покупателя стоимость платежа и стоимость 
--платежа из предыдущей строки со значением по умолчанию 0.0 с сортировкой по дате платежа.
select
	*,
	lag(amount,
	1,
	0.) over (partition by customer_id
order by
	payment_date) as prevamount,
	amount as curamount
from
	payment p 




--ЗАДАНИЕ №3
--С помощью оконной функции определите, на сколько каждый следующий платеж покупателя больше или меньше текущего.
select
	*,
	lag(amount,
	1,
	0.) over (partition by customer_id
order by
	payment_date) as prevamount,
	amount as curamount,
	amount - lag(amount,
	1,
	0.) over (partition by customer_id
order by
	payment_date) as diffamount
from
	payment p 




--ЗАДАНИЕ №4
--С помощью оконной функции для каждого покупателя выведите данные о его последней оплате аренды.
select * from (select
	*,
	row_number () over (partition by customer_id
order by
	payment_date desc) as numofcustanddate
from
	payment p) as tmp 
	where numofcustanddate = 1




--======== ДОПОЛНИТЕЛЬНАЯ ЧАСТЬ ==============

--ЗАДАНИЕ №1
--С помощью оконной функции выведите для каждого сотрудника сумму продаж за август 2005 года 
--с нарастающим итогом по каждому сотруднику и по каждой дате продажи (без учёта времени) 
--с сортировкой по дате.
select
	*,
	sum(amount) over (partition by staff_id) as allsumofstaff,
	sum(amount) over (partition by staff_id,
	payment_date::date
order by
	payment_date)
from
	(
	select
		*
	from
		payment p
	where
		date_trunc('month',
		payment_date) = '2005-08-01 00:00:00') as tmp


--ЗАДАНИЕ №2
--20 августа 2005 года в магазинах проходила акция: покупатель каждого сотого платежа получал
--дополнительную скидку на следующую аренду. С помощью оконной функции выведите всех покупателей,
--которые в день проведения акции получили скидку
select
	customer_id
from
	(
	select
		*,
		row_number () over (
		order by payment_date) as numb
	from
		(
		select
			*
		from
			payment p
		where
			date_trunc('day',
			payment_date) = '2005-08-20 00:00:00') tmp) as tmp2
where
	(numb % 100) = 0



--ЗАДАНИЕ №3
--Для каждой страны определите и выведите одним SQL-запросом покупателей, которые попадают под условия:
-- 1. покупатель, арендовавший наибольшее количество фильмов
-- 2. покупатель, арендовавший фильмов на самую большую сумму
-- 3. покупатель, который последним арендовал фильм
with tmp as (
select
	p.amount,
	c.customer_id,
	c.first_name,
	c.last_name,
	r.rental_date,
	c3.country_id ,
	c3.country,
	count(*) over (partition by r.customer_id) as rentcount,
	sum(amount) over (partition by p.customer_id) as sumamount,
	max(r.rental_date) over (partition by r.customer_id) as maxrent
from 
	rental r
join payment p on
	p.rental_id = r.rental_id
join customer c on
	r.customer_id = c.customer_id
join address a on
	c.address_id = a.address_id
join city c2 on
	c2.city_id = a.city_id
join country c3 on
	c3.country_id = c2.country_id 
),
tmp2 as (
select
	country_id,
	max(rentcount) as maxrentcount,
	max(sumamount) as maxsumamount,
	max(maxrent) as maxmaxrent
from
	tmp
group by
	country_id)
select
	distinct first_name,
	last_name,
	country
from
	tmp
join tmp2 on
	tmp.country_id = tmp2.country_id
where
	rentcount = maxrentcount
	and sumamount = maxsumamount
	and maxrent = maxmaxrent








