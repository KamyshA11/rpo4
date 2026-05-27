-- +goose Up
ALTER TABLE cards ADD COLUMN uid TEXT;

-- Обновляем существующие карты (пример для тестовых данных)
UPDATE cards SET uid = '36CB2006' WHERE number = '1234567890';
UPDATE cards SET uid = '0987654321' WHERE number = '0987654321';
UPDATE cards SET uid = '111122223333' WHERE number = '111122223333';

-- +goose Down
ALTER TABLE cards DROP COLUMN uid;