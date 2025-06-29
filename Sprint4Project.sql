/* Проект «Секреты Тёмнолесья»
 * Цель проекта: изучить влияние характеристик игроков и их игровых персонажей 
 * на покупку внутриигровой валюты «райские лепестки», а также оценить 
 * активность игроков при совершении внутриигровых покупок
 * 
 * Автор: Бутаков Павел Викторович
 * Дата: 11.02.2025
*/

-- Часть 1. Исследовательский анализ данных
-- Задача 1. Исследование доли платящих игроков

-- 1.1. Доля платящих пользователей по всем данным:
-- Напишите ваш запрос здесь
SELECT
    COUNT(*) AS total_players, 
    COUNT(DISTINCT CASE WHEN payer = 1 THEN id END) AS paying_players,  
    ROUND(COUNT(DISTINCT CASE WHEN payer = 1 THEN id END) * 1.0 / COUNT(*) * 100, 2) AS paying_players_ratio  
FROM fantasy.users;

-- 1.2. Доля платящих пользователей в разрезе расы персонажа:
-- Напишите ваш запрос здесь
SELECT
    r.race,  
    COUNT(u.id) AS total_players_by_race, 
    COUNT(DISTINCT CASE WHEN u.payer = 1 THEN u.id END) AS paying_players_by_race,  
    ROUND(COUNT(DISTINCT CASE WHEN u.payer = 1 THEN u.id END) * 1.0 / COUNT(u.id) * 100, 2) AS paying_players_ratio_by_race  
FROM fantasy.users AS u
JOIN fantasy.race AS r ON u.race_id = r.race_id
GROUP BY r.race
ORDER BY paying_players_ratio_by_race DESC;

-- Задача 2. Исследование внутриигровых покупок
-- 2.1. Статистические показатели по полю amount:
-- Напишите ваш запрос здесь
SELECT
    COUNT(*) AS total_purchases,  
    SUM(amount) AS total_amount,  
    MIN(amount) AS min_amount,   
    MAX(amount) AS max_amount,   
    AVG(amount) AS avg_amount,    
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY amount) AS median_amount,  
    STDDEV(amount) AS stddev_amount  
FROM fantasy.events;

-- 2.2: Аномальные нулевые покупки:
-- Напишите ваш запрос здесь
SELECT
    COUNT(*) AS zero_amount_purchases,  
    ROUND(COUNT(*) * 1.0 / (SELECT COUNT(*) FROM fantasy.events) * 100, 2) AS zero_amount_ratio  
FROM fantasy.events
WHERE amount = 0; 

-- 2.3: Сравнительный анализ активности платящих и неплатящих игроков:
-- Напишите ваш запрос здесь
SELECT
    u.payer,  
    COUNT(DISTINCT u.id) AS total_players,  
    COUNT(e.transaction_id) * 1.0 / COUNT(DISTINCT u.id) AS avg_purchases_per_player,  
    SUM(e.amount) * 1.0 / COUNT(DISTINCT u.id) AS avg_amount_per_player  
FROM fantasy.users AS u
LEFT JOIN fantasy.events AS e ON u.id = e.id AND e.amount <> 0
GROUP BY u.payer;

-- 2.4: Популярные эпические предметы:
-- Напишите ваш запрос здесь
SELECT
    i.game_items,  
    COUNT(e.transaction_id) AS total_sales,  
    ROUND(COUNT(e.transaction_id) * 1.0 / (SELECT COUNT(*) FROM fantasy.events ) * 100, 2) AS sales_ratio, 
    ROUND(COUNT(DISTINCT e.id) * 1.0 / (SELECT COUNT(DISTINCT id) FROM fantasy.events) * 100, 2) AS players_ratio  
FROM fantasy.events AS e
JOIN fantasy.items AS i ON e.item_code = i.item_code
WHERE e.amount <> 0
GROUP BY i.item_code
ORDER BY total_sales DESC;

-- Часть 2. Решение ad hoc-задач
-- Задача 1. Зависимость активности игроков от расы персонажа:
-- Напишите ваш запрос здесь
WITH
total_players_by_race AS (
    SELECT
        r.race,
        COUNT(u.id) AS total_players
    FROM fantasy.users AS u
    JOIN fantasy.race AS r ON u.race_id = r.race_id
    GROUP BY r.race
),
players_with_purchases_by_race AS (
    SELECT
        r.race,
        COUNT(DISTINCT u.id) AS players_with_purchases,
        COUNT(DISTINCT CASE WHEN u.payer = 1 THEN u.id END) AS paying_players
    FROM fantasy.users AS u
    JOIN fantasy.race AS r ON u.race_id = r.race_id
    JOIN fantasy.events AS e ON u.id = e.id
    WHERE e.amount <> 0
    GROUP BY r.race
),
player_activity_by_race AS (
    SELECT
        r.race,
        COUNT(e.transaction_id) AS total_purchases,
        SUM(e.amount) AS total_amount
    FROM fantasy.users AS u
    JOIN fantasy.race AS r ON u.race_id = r.race_id
    JOIN fantasy.events AS e ON u.id = e.id
    WHERE e.amount <> 0
    GROUP BY r.race
)
SELECT
    t.race,
    t.total_players,
    p.players_with_purchases,
    ROUND((p.players_with_purchases * 1.0 / t.total_players * 100)::numeric, 2) AS players_with_purchases_ratio,
    ROUND((p.paying_players * 1.0 / p.players_with_purchases * 100)::numeric, 2) AS paying_players_ratio,
    ROUND((a.total_purchases * 1.0 / p.players_with_purchases)::numeric, 2) AS avg_purchases_per_player,
    ROUND((a.total_amount * 1.0 / a.total_purchases)::numeric, 2) AS avg_amount_per_purchase,
    ROUND((a.total_amount * 1.0 / p.players_with_purchases)::numeric, 2) AS avg_total_amount_per_player
FROM total_players_by_race AS t
JOIN players_with_purchases_by_race AS p ON t.race = p.race
JOIN player_activity_by_race AS a ON t.race = a.race
ORDER BY t.race;

-- Задача 2: Частота покупок
-- Напишите ваш запрос здесь
