-- ============================================
-- FYNA - Finance AI Application
-- Migration V17: Insert Default System Categories
-- ============================================

-- Income Categories
INSERT INTO categories (id, user_id, parent_id, name, icon, color, type, is_system, is_active, display_order)
VALUES 
    -- Main Income Categories
    (uuid_generate_v4(), NULL, NULL, 'Salário', 'briefcase', '#4CAF50', 'INCOME', TRUE, TRUE, 1),
    (uuid_generate_v4(), NULL, NULL, 'Freelance', 'laptop', '#8BC34A', 'INCOME', TRUE, TRUE, 2),
    (uuid_generate_v4(), NULL, NULL, 'Investimentos', 'trending-up', '#00BCD4', 'INCOME', TRUE, TRUE, 3),
    (uuid_generate_v4(), NULL, NULL, 'Presente', 'gift', '#E91E63', 'INCOME', TRUE, TRUE, 4),
    (uuid_generate_v4(), NULL, NULL, 'Reembolso', 'refresh-cw', '#9C27B0', 'INCOME', TRUE, TRUE, 5),
    (uuid_generate_v4(), NULL, NULL, 'Outras Receitas', 'plus-circle', '#607D8B', 'INCOME', TRUE, TRUE, 6);

-- Expense Categories
INSERT INTO categories (id, user_id, parent_id, name, icon, color, type, is_system, is_active, display_order)
VALUES 
    -- Food & Dining
    (uuid_generate_v4(), NULL, NULL, 'Alimentação', 'utensils', '#FF5722', 'EXPENSE', TRUE, TRUE, 10),
    (uuid_generate_v4(), NULL, NULL, 'Restaurantes', 'coffee', '#FF7043', 'EXPENSE', TRUE, TRUE, 11),
    (uuid_generate_v4(), NULL, NULL, 'Supermercado', 'shopping-cart', '#FF8A65', 'EXPENSE', TRUE, TRUE, 12),
    
    -- Transportation
    (uuid_generate_v4(), NULL, NULL, 'Transporte', 'car', '#3F51B5', 'EXPENSE', TRUE, TRUE, 20),
    (uuid_generate_v4(), NULL, NULL, 'Combustível', 'droplet', '#5C6BC0', 'EXPENSE', TRUE, TRUE, 21),
    (uuid_generate_v4(), NULL, NULL, 'Transporte Público', 'bus', '#7986CB', 'EXPENSE', TRUE, TRUE, 22),
    (uuid_generate_v4(), NULL, NULL, 'Aplicativos de Transporte', 'smartphone', '#9FA8DA', 'EXPENSE', TRUE, TRUE, 23),
    
    -- Housing
    (uuid_generate_v4(), NULL, NULL, 'Moradia', 'home', '#795548', 'EXPENSE', TRUE, TRUE, 30),
    (uuid_generate_v4(), NULL, NULL, 'Aluguel', 'key', '#8D6E63', 'EXPENSE', TRUE, TRUE, 31),
    (uuid_generate_v4(), NULL, NULL, 'Condomínio', 'building', '#A1887F', 'EXPENSE', TRUE, TRUE, 32),
    (uuid_generate_v4(), NULL, NULL, 'Manutenção Casa', 'tool', '#BCAAA4', 'EXPENSE', TRUE, TRUE, 33),
    
    -- Bills & Utilities
    (uuid_generate_v4(), NULL, NULL, 'Contas', 'file-text', '#009688', 'EXPENSE', TRUE, TRUE, 40),
    (uuid_generate_v4(), NULL, NULL, 'Energia', 'zap', '#26A69A', 'EXPENSE', TRUE, TRUE, 41),
    (uuid_generate_v4(), NULL, NULL, 'Água', 'droplet', '#4DB6AC', 'EXPENSE', TRUE, TRUE, 42),
    (uuid_generate_v4(), NULL, NULL, 'Internet', 'wifi', '#80CBC4', 'EXPENSE', TRUE, TRUE, 43),
    (uuid_generate_v4(), NULL, NULL, 'Telefone', 'phone', '#B2DFDB', 'EXPENSE', TRUE, TRUE, 44),
    
    -- Health
    (uuid_generate_v4(), NULL, NULL, 'Saúde', 'heart', '#F44336', 'EXPENSE', TRUE, TRUE, 50),
    (uuid_generate_v4(), NULL, NULL, 'Farmácia', 'plus-square', '#EF5350', 'EXPENSE', TRUE, TRUE, 51),
    (uuid_generate_v4(), NULL, NULL, 'Plano de Saúde', 'shield', '#E57373', 'EXPENSE', TRUE, TRUE, 52),
    (uuid_generate_v4(), NULL, NULL, 'Academia', 'activity', '#EF9A9A', 'EXPENSE', TRUE, TRUE, 53),
    
    -- Education
    (uuid_generate_v4(), NULL, NULL, 'Educação', 'book', '#2196F3', 'EXPENSE', TRUE, TRUE, 60),
    (uuid_generate_v4(), NULL, NULL, 'Cursos', 'award', '#42A5F5', 'EXPENSE', TRUE, TRUE, 61),
    (uuid_generate_v4(), NULL, NULL, 'Livros', 'book-open', '#64B5F6', 'EXPENSE', TRUE, TRUE, 62),
    
    -- Entertainment
    (uuid_generate_v4(), NULL, NULL, 'Lazer', 'smile', '#9C27B0', 'EXPENSE', TRUE, TRUE, 70),
    (uuid_generate_v4(), NULL, NULL, 'Streaming', 'play-circle', '#AB47BC', 'EXPENSE', TRUE, TRUE, 71),
    (uuid_generate_v4(), NULL, NULL, 'Jogos', 'gamepad', '#BA68C8', 'EXPENSE', TRUE, TRUE, 72),
    (uuid_generate_v4(), NULL, NULL, 'Viagens', 'map', '#CE93D8', 'EXPENSE', TRUE, TRUE, 73),
    
    -- Shopping
    (uuid_generate_v4(), NULL, NULL, 'Compras', 'shopping-bag', '#E91E63', 'EXPENSE', TRUE, TRUE, 80),
    (uuid_generate_v4(), NULL, NULL, 'Roupas', 'scissors', '#EC407A', 'EXPENSE', TRUE, TRUE, 81),
    (uuid_generate_v4(), NULL, NULL, 'Eletrônicos', 'monitor', '#F06292', 'EXPENSE', TRUE, TRUE, 82),
    
    -- Personal Care
    (uuid_generate_v4(), NULL, NULL, 'Cuidados Pessoais', 'user', '#FF9800', 'EXPENSE', TRUE, TRUE, 90),
    (uuid_generate_v4(), NULL, NULL, 'Beleza', 'star', '#FFA726', 'EXPENSE', TRUE, TRUE, 91),
    
    -- Pets
    (uuid_generate_v4(), NULL, NULL, 'Pets', 'heart', '#8D6E63', 'EXPENSE', TRUE, TRUE, 100),
    
    -- Financial
    (uuid_generate_v4(), NULL, NULL, 'Financeiro', 'dollar-sign', '#607D8B', 'EXPENSE', TRUE, TRUE, 110),
    (uuid_generate_v4(), NULL, NULL, 'Taxas Bancárias', 'credit-card', '#78909C', 'EXPENSE', TRUE, TRUE, 111),
    (uuid_generate_v4(), NULL, NULL, 'Impostos', 'file', '#90A4AE', 'EXPENSE', TRUE, TRUE, 112),
    (uuid_generate_v4(), NULL, NULL, 'Seguros', 'shield', '#B0BEC5', 'EXPENSE', TRUE, TRUE, 113),
    
    -- Other
    (uuid_generate_v4(), NULL, NULL, 'Outras Despesas', 'more-horizontal', '#9E9E9E', 'EXPENSE', TRUE, TRUE, 200);

-- Transfer Category
INSERT INTO categories (id, user_id, parent_id, name, icon, color, type, is_system, is_active, display_order)
VALUES 
    (uuid_generate_v4(), NULL, NULL, 'Transferência', 'repeat', '#673AB7', 'TRANSFER', TRUE, TRUE, 300);
