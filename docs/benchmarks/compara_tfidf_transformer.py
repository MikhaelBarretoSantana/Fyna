"""
Compara a acuracia do classificador semantico do Fyna usando
Sentence Transformers (caminho principal) versus TF-IDF (fallback).

Usa o codigo real do projeto (apps/ai/app/services/classifier.py)
sem depender do backend Spring ou do PostgreSQL. Constroi um corpus
sintetico em portugues representativo do dominio.

Uso:
    python compara_tfidf_transformer.py

Saida:
    Imprime no terminal a acuracia de cada backend e a queda absoluta
    e relativa do TF-IDF em relacao ao Sentence Transformers.
"""
from __future__ import annotations

import os
import sys

# Permite importar apps/ai/app/services/classifier.py como modulo
PROJECT_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
AI_PATH = os.path.join(PROJECT_ROOT, "apps", "ai")
if AI_PATH not in sys.path:
    sys.path.insert(0, AI_PATH)

import numpy as np
import app.services.classifier as clf

# ────────────────────────────────────────────────────────────────────
# Categorias canonicas (nomes que aparecem como ancora semantica)
# ────────────────────────────────────────────────────────────────────
CATEGORIAS = [
    "Alimentacao",
    "Transporte",
    "Lazer",
    "Saude",
    "Educacao",
    "Moradia",
    "Vestuario",
    "Streaming",
    "Combustivel",
    "Mercado",
]

# ────────────────────────────────────────────────────────────────────
# Corpus sintetico: descricoes -> rotulo verdadeiro
# Distribuicao parecida com a do TCC (~30 itens por categoria)
# ────────────────────────────────────────────────────────────────────
CORPUS: list[tuple[str, str]] = []

_TEMPLATES = {
    "Alimentacao": [
        "almoco restaurante centro",
        "jantar comida japonesa",
        "lanche padaria manha",
        "pizza delivery domingo",
        "cafe da tarde cafeteria",
        "marmita executivo trabalho",
        "hamburguer fast food",
        "sushi restaurante japones",
        "feijoada restaurante popular",
        "salgado lanchonete",
    ],
    "Transporte": [
        "uber centro cidade",
        "99 taxi para casa",
        "passagem onibus mensal",
        "metro cartao recarga",
        "taxi aeroporto",
        "uber para o trabalho",
        "transporte aplicativo noite",
        "passagem urbana intermunicipal",
        "bilhete unico recarga",
        "viagem app transporte",
    ],
    "Lazer": [
        "cinema sessao tarde",
        "ingresso show musical",
        "bar happy hour amigos",
        "balada noite final de semana",
        "teatro espetaculo classico",
        "parque diversao familia",
        "evento cultural ingresso",
        "passeio shopping fim de semana",
        "festival musica eletronica",
        "boate noite domingo",
    ],
    "Saude": [
        "consulta medica clinica",
        "exame laboratorio sangue",
        "remedio farmacia generico",
        "consulta dentista limpeza",
        "exame ressonancia magnetica",
        "medicamento controlado farmacia",
        "consulta dermatologista",
        "vacina particular gripe",
        "consulta psicologo sessao",
        "exame oftalmologico",
    ],
    "Educacao": [
        "mensalidade faculdade janeiro",
        "curso online plataforma",
        "livro tecnico programacao",
        "material escolar caderno",
        "anuidade idiomas curso",
        "mensalidade cursinho preparatorio",
        "ebook tecnico aprendizado",
        "taxa inscricao prova",
        "apostila concurso publico",
        "material universitario",
    ],
    "Moradia": [
        "aluguel apartamento mensal",
        "conta luz energia eletrica",
        "conta agua saneamento",
        "internet fibra mensal",
        "condominio mensal predio",
        "iptu parcela anual",
        "gas botijao residencial",
        "manutencao predio rateio",
        "aluguel garagem mensal",
        "consumo energia bandeira",
    ],
    "Vestuario": [
        "camiseta loja shopping",
        "calca jeans roupa casual",
        "tenis esportivo corrida",
        "vestido festa loja",
        "moletom inverno casaco",
        "blusa de frio loja",
        "sapato social cor preta",
        "roupa intima loja online",
        "casaco couro inverno",
        "bermuda verao loja",
    ],
    "Streaming": [
        "assinatura netflix mensal",
        "assinatura spotify familia",
        "assinatura prime video",
        "mensalidade disney plus",
        "assinatura globoplay",
        "youtube premium mensal",
        "deezer assinatura individual",
        "hbo max mensal",
        "apple tv plus mensal",
        "tidal streaming musica",
    ],
    "Combustivel": [
        "gasolina posto bandeira",
        "etanol posto comum",
        "diesel s10 posto",
        "abastecimento gasolina aditivada",
        "tanque cheio gasolina",
        "etanol carro flex",
        "posto combustivel rodovia",
        "abastecimento moto gasolina",
        "diesel veiculo utilitario",
        "combustivel posto self",
    ],
    "Mercado": [
        "supermercado compras semana",
        "compras mercado mensal",
        "hortifruti feira semana",
        "atacado mercado familia",
        "mercado bairro feira",
        "carrinho mercado sabado",
        "compras supermercado domingo",
        "hipermercado compras mes",
        "mercadinho bairro lanche",
        "feira livre legumes",
    ],
}

for cat, descrs in _TEMPLATES.items():
    for d in descrs:
        CORPUS.append((d, cat))


# ────────────────────────────────────────────────────────────────────
# Predicao por similaridade do cosseno (espelha classifier.classify_transaction)
# ────────────────────────────────────────────────────────────────────
def prever(descricao: str, categorias: list[str]) -> str:
    """Retorna a categoria de maior similaridade do cosseno."""
    textos = [descricao] + categorias
    vetores = clf._encode_texts(textos)
    desc_v = vetores[0]
    cat_v = vetores[1:]
    sim = np.dot(cat_v, desc_v)
    return categorias[int(np.argmax(sim))]


def avaliar(label: str) -> tuple[int, int]:
    """Roda o corpus e retorna (acertos, total)."""
    acertos = 0
    for descr, verdadeiro in CORPUS:
        previsto = prever(descr, CATEGORIAS)
        if previsto == verdadeiro:
            acertos += 1
    return acertos, len(CORPUS)


def reset_backend(forcar_tfidf: bool):
    """Reseta o estado global do classificador para forcar um caminho."""
    clf._embedding_model = None
    clf._use_tfidf_fallback = forcar_tfidf


def main():
    print(f"Corpus: {len(CORPUS)} transacoes em {len(CATEGORIAS)} categorias")
    print()

    print(">>> Rodando com Sentence Transformers (caminho principal)...")
    reset_backend(forcar_tfidf=False)
    acertos_st, total = avaliar("sentence-transformers")
    acc_st = acertos_st / total
    print(f"    Acertos: {acertos_st}/{total}  -->  Acuracia = {acc_st:.2%}")
    print()

    print(">>> Rodando com TF-IDF (fallback forcado)...")
    reset_backend(forcar_tfidf=True)
    acertos_tf, total = avaliar("tfidf")
    acc_tf = acertos_tf / total
    print(f"    Acertos: {acertos_tf}/{total}  -->  Acuracia = {acc_tf:.2%}")
    print()

    delta_abs = (acc_st - acc_tf) * 100
    delta_rel = ((acc_st - acc_tf) / acc_st) * 100 if acc_st > 0 else 0.0
    print("-" * 60)
    print(f"Queda absoluta:  {delta_abs:+.2f} pontos percentuais")
    print(f"Queda relativa:  {delta_rel:+.2f}% sobre a acuracia do transformer")


if __name__ == "__main__":
    main()
