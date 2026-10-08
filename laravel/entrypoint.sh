#!/bin/sh
set -e

# MySQL コンテナにつながるまで待つ
until php -r 'new PDO("mysql:host=mysql;port=3306", "laravel", "password");' 2>/dev/null; do
    echo "MySQL の起動を待っています...（mysql フォルダで docker compose up -d をしましたか？）"
    sleep 3
done

# 初回だけ：src が空なら Laravel をインストールして MySQL につなぐ
if [ ! -f artisan ]; then
    echo "Laravel をインストールしています（初回だけ数分かかります）..."
    composer create-project laravel/laravel . --prefer-dist --no-interaction

    # .env のデータベース設定を MySQL コンテナに書きかえる
    sed -i '/^#* *DB_/d' .env
    cat >> .env <<'ENV'

DB_CONNECTION=mysql
DB_HOST=mysql
DB_PORT=3306
DB_DATABASE=laravel
DB_USERNAME=laravel
DB_PASSWORD=password
ENV

    php artisan migrate --force
fi

# プロジェクトはあるが vendor がない（GitHub からクローンした直後など）
if [ ! -d vendor ]; then
    composer install --no-interaction
fi

exec "$@"
