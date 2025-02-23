CREATE OR REPLACE FUNCTION calculate_annual_salary(
    p_monthly_salary NUMBER,
    p_bonus_percent NUMBER
) RETURN NUMBER IS
    annual_salary NUMBER;
    bonus_ratio NUMBER;
BEGIN
    IF p_monthly_salary IS NULL THEN
        RAISE_APPLICATION_ERROR(-20001, 'Error: Monthly salary cannot be NULL');
    END IF;
    IF p_bonus_percent IS NULL THEN
        RAISE_APPLICATION_ERROR(-20001, 'Error: Bonus percentage cannot be NULL');
    END IF;
    IF p_monthly_salary <= 0 OR p_bonus_percent < 0 THEN
        RAISE_APPLICATION_ERROR(-20001, 'Некорректные данные: зарплата должна быть > 0, бонус >= 0');
    END IF;

    bonus_ratio := p_bonus_percent / 100;
    annual_salary := (1 + bonus_ratio) * 12 * p_monthly_salary;
    
    RETURN annual_salary;
END;