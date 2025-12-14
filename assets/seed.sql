CREATE TABLE products (
  id INTEGER PRIMARY KEY AUTOINCREMENT,

  deal_date TEXT,        -- 거래일자
  client TEXT,           -- 거래처
  category TEXT,         -- 분류
  manufacturer TEXT,     -- 제조사

  name TEXT,             -- 제품명
  spec TEXT,             -- 규격
  unit TEXT,             -- 단위

  quantity INTEGER NOT NULL DEFAULT 1,     -- 수량
  total_price INTEGER NOT NULL DEFAULT 0,  -- 총금액

  note TEXT              -- 비고
);
