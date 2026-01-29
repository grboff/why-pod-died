#!/usr/bin/env bash

# Подключаем библиотеку
source lib/common.sh

# Тестируем логирование
log_info "This is info"
log_success "This is success"
log_warn "This is warning"
log_error "This is error"

echo ""

# Тестируем проверку зависимостей
log_info "Checking dependencies..."
check_dependencies
log_success "All dependencies found!"
