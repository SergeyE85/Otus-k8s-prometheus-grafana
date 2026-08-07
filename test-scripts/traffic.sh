#!/bin/bash

# Базовый URL приложения
BASE_URL="http://arch.homework:8080"

# Функция для генерации случайного имени пользователя
generate_random_name() {

	length=12
	result=""
	for ((i=0; i<length; i++)); do
	  # 62 символа в наборе a-z0-9
	  index=$(( RANDOM % 62 ))
	  char="abcdefghijklmnopqrstuvwxyz0123456789"
	  result="${result}${char:index:1}"
	done
	echo "$result"

}

# Функция для генерации случайного email
generate_random_email() {
    local name=$(generate_random_name)
    echo "${name}@example.com"
}

# Функция для генерации случайной даты
generate_random_date() {
	local start_ts=$(date -d '2000-01-01 00:00:00' +%s)
	local end_ts=$(date -d '2030-12-31 23:59:59' +%s)
	local random_ts=$(( start_ts + RANDOM * (end_ts - start_ts) / 32767 ))
	local data=$(date -d "@$random_ts" '+%Y-%m-%d %H:%M:%S')
	echo "$data"
}

# Функция для создания пользователя
create_user() {
    local name=$(generate_random_name)
    local email=$(generate_random_email)
    local birthdate=$(generate_random_date)
    
    echo "[$(date)] Creating user: $name ($email, $birthdate)"
    
    local response=$(curl -s -X POST "$BASE_URL/users" \
        -H "Content-Type: application/json" \
        -d "{
            \"Name\": \"$name\",
            \"Email\": \"$email\",
            \"BirthDate\": \"$birthdate\"
        }")
    
    echo "$response"
    # Извлекаем ID созданного пользователя
    local user_id=$(echo "$response")
    echo "$user_id" >> user_ids.txt
    echo "Created user ID: $user_id"
}

# Функция для получения пользователя
get_user() {
    if [ ! -f "user_ids.txt" ] || [ ! -s "user_ids.txt" ]; then
        echo "No users to get"
        return
    fi
    
    # Выбираем случайный ID из файла
    local user_id=$(shuf -n 1 user_ids.txt)
    if [ -z "$user_id" ]; then
        echo "No valid user ID found"
        return
    fi
    
    echo "[$(date)] Getting user with ID: $user_id"
    curl -s -X GET "$BASE_URL/users/$user_id"
    echo ""
}

# Функция для получения порции пользователей
get_users_batch() {
    
	local batchSize=$((RANDOM % 1000))
	local skip=$((RANDOM % 1000))
	
    echo "[$(date)] Getting users batch with skip = $skip and batchSize = $batchSize"
    curl -s -X GET "$BASE_URL/users/batch?skip=$skip&batchSize=$batchSize"
    echo ""
}

# Функция для получения всех пользователей
get_all_users() {   
    echo "[$(date)] Getting all users"
    curl -s -X GET "$BASE_URL/users/all"
    echo ""
}

# Функция для обновления пользователя
update_user() {
    if [ ! -f "user_ids.txt" ] || [ ! -s "user_ids.txt" ]; then
        echo "No users to update"
        return
    fi
    
    # Выбираем случайный ID из файла
    local user_id=$(shuf -n 1 user_ids.txt)
    if [ -z "$user_id" ]; then
        echo "No valid user ID found"
        return
    fi
    
    local new_email=$(generate_random_email)
    
    echo "[$(date)] Updating user with ID: $user_id, new email: $new_email"	
	
	curl -X PATCH "$BASE_URL/users/$user_id" \
		-H "Content-Type: application/json" \
		-d '[{"op":"replace","path":"/email","value":"$new_email"}]'
		
    echo ""
}

# Функция для удаления пользователя
delete_user() {
    if [ ! -f "user_ids.txt" ] || [ ! -s "user_ids.txt" ]; then
        echo "No users to delete"
        return
    fi
    
    # Выбираем случайный ID из файла
    local user_id=$(shuf -n 1 user_ids.txt)
    if [ -z "$user_id" ]; then
        echo "No valid user ID found"
        return
    fi
    
    echo "[$(date)] Deleting user with ID: $user_id"
    curl -s -X DELETE "$BASE_URL/users/$user_id"
    echo ""
    
    # Удаляем ID из файла
    sed -i "/^$user_id$/d" user_ids.txt
}

# Основной цикл генерации трафика
while true; do
    # Случайно выбираем действие
    case $((RANDOM % 10)) in
        0|1)
            get_all_users
            ;;
        2)
            get_users_batch
            ;;
        3|4|5)
            create_user
            ;;
        6|7)
            get_user
            ;;
        8)
            update_user
            ;;
        9)
            delete_user
            ;;
    esac
    
    # Случайная пауза между запросами (0.5 - 3 секунды)
    sleep $(awk "BEGIN {print 0.5 + ($RANDOM / 32767 * 2.5)}")
done