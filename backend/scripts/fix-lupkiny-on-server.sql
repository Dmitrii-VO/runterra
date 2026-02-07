SELECT id, name, status, city_id FROM clubs WHERE name = U&'\041B\0443\043F\043A\0438\043D\044B';
UPDATE clubs SET status = 'active', updated_at = NOW() WHERE name = U&'\041B\0443\043F\043A\0438\043D\044B';
SELECT id, name, status FROM clubs WHERE name = U&'\041B\0443\043F\043A\0438\043D\044B';
