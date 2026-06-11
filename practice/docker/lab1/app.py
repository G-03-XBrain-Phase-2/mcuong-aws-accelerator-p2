import os
import time
import psycopg2
from flask import Flask

app = Flask(__name__)

# Lấy cấu hình kết nối DB từ biến môi trường
DB_HOST = os.environ.get('DB_HOST', 'db-postgres')
DB_NAME = os.environ.get('DB_NAME', 'mydb')
DB_USER = os.environ.get('DB_USER', 'myuser')
DB_PASS = os.environ.get('DB_PASS', 'mypassword')

def get_db_connection():
    while True:
        try:
            conn = psycopg2.connect(
                host=DB_HOST,
                database=DB_NAME,
                user=DB_USER,
                password=DB_PASS
            )
            return conn
        except psycopg2.OperationalError:
            print("Đang chờ PostgreSQL khởi động...")
            time.sleep(2)

# Khởi tạo bảng visits
conn = get_db_connection()
cur = conn.cursor()
cur.execute('''
    CREATE TABLE IF NOT EXISTS visits (
        id SERIAL PRIMARY KEY,
        count INT NOT NULL
    );
''')
cur.execute('SELECT count FROM visits WHERE id=1;')
row = cur.fetchone()
if not row:
    cur.execute('INSERT INTO visits (id, count) VALUES (1, 0);')
conn.commit()
cur.close()
conn.close()

@app.route('/')
def hello():
    conn = get_db_connection()
    cur = conn.cursor()
    
    # Tăng biến đếm trong Database
    cur.execute('UPDATE visits SET count = count + 1 WHERE id = 1;')
    conn.commit()
    
    # Lấy giá trị mới
    cur.execute('SELECT count FROM visits WHERE id = 1;')
    count = cur.fetchone()[0]
    
    cur.close()
    conn.close()
    return f"<h3>Xin chào! Số lượt truy cập hệ thống hiện tại là: {count}</h3>\n"

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)