-- ============================================================================
-- Release 1.0.6 — 09: Seed Default Account Categories Chart of Accounts
-- Inserts 5 root parent categories and 30 standard subcategories.
-- Idempotent: safe to re-run.
-- ============================================================================

DO $$
DECLARE
    v_created_by INTEGER := 2; -- admin user
    v_asset_id INTEGER;
    v_liability_id INTEGER;
    v_equity_id INTEGER;
    v_income_id INTEGER;
    v_expense_id INTEGER;
BEGIN
    -- 1. Insert Root Categories (Parents)
    INSERT INTO public.account_categories (
        category_code, category_name, account_type, parent_category_id, description, is_system, is_active, created_by
    )
    SELECT 'ASSET', 'Assets', 'asset', NULL, 'Money and resources owned', true, true, v_created_by
    WHERE NOT EXISTS (SELECT 1 FROM public.account_categories WHERE category_code = 'ASSET');

    INSERT INTO public.account_categories (
        category_code, category_name, account_type, parent_category_id, description, is_system, is_active, created_by
    )
    SELECT 'LIABILITY', 'Liabilities', 'liability', NULL, 'Amounts owed', true, true, v_created_by
    WHERE NOT EXISTS (SELECT 1 FROM public.account_categories WHERE category_code = 'LIABILITY');

    INSERT INTO public.account_categories (
        category_code, category_name, account_type, parent_category_id, description, is_system, is_active, created_by
    )
    SELECT 'EQUITY', 'Equity', 'equity', NULL, 'Opening balances and personal equity', true, true, v_created_by
    WHERE NOT EXISTS (SELECT 1 FROM public.account_categories WHERE category_code = 'EQUITY');

    INSERT INTO public.account_categories (
        category_code, category_name, account_type, parent_category_id, description, is_system, is_active, created_by
    )
    SELECT 'INCOME', 'Income', 'income', NULL, 'Income received', true, true, v_created_by
    WHERE NOT EXISTS (SELECT 1 FROM public.account_categories WHERE category_code = 'INCOME');

    INSERT INTO public.account_categories (
        category_code, category_name, account_type, parent_category_id, description, is_system, is_active, created_by
    )
    SELECT 'EXPENSE', 'Expenses', 'expense', NULL, 'Personal spending', true, true, v_created_by
    WHERE NOT EXISTS (SELECT 1 FROM public.account_categories WHERE category_code = 'EXPENSE');

    -- 2. Resolve Root Parent IDs
    SELECT account_id INTO v_asset_id FROM public.account_categories WHERE category_code = 'ASSET' LIMIT 1;
    SELECT account_id INTO v_liability_id FROM public.account_categories WHERE category_code = 'LIABILITY' LIMIT 1;
    SELECT account_id INTO v_equity_id FROM public.account_categories WHERE category_code = 'EQUITY' LIMIT 1;
    SELECT account_id INTO v_income_id FROM public.account_categories WHERE category_code = 'INCOME' LIMIT 1;
    SELECT account_id INTO v_expense_id FROM public.account_categories WHERE category_code = 'EXPENSE' LIMIT 1;

    -- 3. Insert All Child Categories
    INSERT INTO public.account_categories (
        category_code, category_name, account_type, parent_category_id, description, is_system, is_active, created_by
    )
    SELECT t.category_code, t.category_name, t.account_type, t.parent_id, t.description, false, true, v_created_by
    FROM (
        VALUES
            -- Asset Subcategories
            ('BANK', 'Bank Accounts', 'asset', v_asset_id, 'Money held in bank accounts'),
            ('CASH', 'Cash Holdings', 'asset', v_asset_id, 'Physical cash holdings'),
            ('UPI', 'UPI Wallets', 'asset', v_asset_id, 'UPI and wallet balances'),
            ('INVESTMENT', 'Investments', 'asset', v_asset_id, 'Investment assets'),

            -- Liability Subcategories
            ('CREDIT_CARD', 'Credit Card Payable', 'liability', v_liability_id, 'Outstanding credit card balances'),
            ('LOAN_PAYABLE', 'Loans Payable', 'liability', v_liability_id, 'Outstanding loans'),
            ('FUND_RESTORE', 'Fund Restoration Payable', 'liability', v_liability_id, 'Money borrowed from reserved funds and still to be restored'),

            -- Equity Subcategories
            ('OPENING_EQUITY', 'Opening Balance Equity', 'equity', v_equity_id, 'Balancing account for initial balances'),
            ('NET_WORTH_ADJ', 'Personal Net Worth Adjustment', 'equity', v_equity_id, 'Approved personal equity adjustments'),

            -- Income Subcategories
            ('SALARY', 'Salary', 'income', v_income_id, 'Salary received'),
            ('BONUS', 'Bonus and Incentives', 'income', v_income_id, 'Bonuses and incentives'),
            ('INTEREST_INCOME', 'Interest Income', 'income', v_income_id, 'Interest earned'),
            ('OTHER_INCOME', 'Other Income', 'income', v_income_id, 'Other income received'),

            -- Expense Subcategories
            ('FOOD', 'Food and Dining', 'expense', v_expense_id, 'Restaurants and prepared food'),
            ('GROCERY', 'Groceries', 'expense', v_expense_id, 'Grocery purchases'),
            ('VEGETABLES', 'Vegetables and Fruits', 'expense', v_expense_id, 'Fresh produce'),
            ('HOUSEHOLD', 'Household Supplies', 'expense', v_expense_id, 'Household necessities'),
            ('HOUSING', 'Housing and Rent', 'expense', v_expense_id, 'Rent and housing costs'),
            ('UTILITIES', 'Electricity and Utilities', 'expense', v_expense_id, 'Electricity, water and utilities'),
            ('INTERNET', 'Mobile and Internet', 'expense', v_expense_id, 'Phone and internet bills'),
            ('TRANSPORT', 'Transport and Fuel', 'expense', v_expense_id, 'Travel and vehicle fuel'),
            ('MEDICAL', 'Medical and Healthcare', 'expense', v_expense_id, 'Medical and healthcare costs'),
            ('FAMILY', 'Family Expenses', 'expense', v_expense_id, 'Family-related spending'),
            ('FAMILY_ALLOCATION', 'Wife and Family Allocation', 'expense', v_expense_id, 'Family spending allocation; classify based on the actual money movement'),
            ('EDUCATION', 'Education', 'expense', v_expense_id, 'Education-related costs'),
            ('SHOPPING', 'Shopping and Personal Care', 'expense', v_expense_id, 'Personal purchases'),
            ('ENTERTAINMENT', 'Entertainment', 'expense', v_expense_id, 'Entertainment and recreation'),
            ('INSURANCE', 'Insurance', 'expense', v_expense_id, 'Insurance premiums'),
            ('BANK_CHARGES', 'Bank Charges', 'expense', v_expense_id, 'Bank fees and charges'),
            ('OTHER_EXPENSE', 'Other Expenses', 'expense', v_expense_id, 'Miscellaneous personal expenses')
    ) AS t(category_code, category_name, account_type, parent_id, description)
    WHERE NOT EXISTS (
        SELECT 1 FROM public.account_categories ac
        WHERE ac.category_code = t.category_code
    );
END $$;
