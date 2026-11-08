import json
import os
import sys

from fastapi import FastAPI, Query
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel

PASTA_SERVIDOR = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, PASTA_SERVIDOR)

from classificacao import classificar_area
from recomendador.preprocessamento import preprocessar  
from recomendador.recomendacao import (  
    MotorRecomendacao, Trabalho,
)
from recomendador.representacao import (  
    VetorizadorTFIDF, similaridade_cosseno,
)
from recomendador.topicos import ModeloTopicos  

CAMINHO_CORPUS = os.path.join(PASTA_SERVIDOR, "data", "corpus.json")

class TrabalhoResposta(BaseModel):
    id: str
    titulo: str
    resumo: str
    area: str
    ano: int
    fonte: str = ""


class RecomendacaoResposta(BaseModel):
    titulo: str
    area: str
    ano: int
    score: float
    fonte: str = ""

class Estado:
    trabalhos: list[Trabalho] = []
    motor: MotorRecomendacao | None = None
    modelo_topicos: ModeloTopicos | None = None

estado = Estado()

def carregar_corpus() -> list[dict]:
    if not os.path.isfile(CAMINHO_CORPUS):
        print(f"[AVISO] corpus não encontrado em {CAMINHO_CORPUS}.", file=sys.stderr)
        print("        Copie o corpus.json da coleta para essa pasta.", file=sys.stderr)
        return []
    with open(CAMINHO_CORPUS, encoding="utf-8") as f:
        return json.load(f)


def preparar_motor() -> None:
    """Carrega o corpus, vetoriza, modela tópicos e cria o motor (uma vez)."""
    corpus = carregar_corpus()
    if not corpus:
        return

    documentos_tokens = [
        preprocessar(f"{doc.get('titulo','')} {doc.get('resumo','')}")
        for doc in corpus
    ]
    vetorizador = VetorizadorTFIDF()
    vetores = vetorizador.ajustar_transformar(documentos_tokens)

    modelo = ModeloTopicos(limiar_similaridade=0.06)
    modelo.ajustar(vetores, documentos_tokens)

    trabalhos = []
    for doc, tokens, vetor, topico in zip(
        corpus, documentos_tokens, vetores, modelo.atribuicoes
    ):
        trabalhos.append(Trabalho(
            id=str(doc.get("id", "")),
            titulo=doc.get("titulo", ""),
            resumo=doc.get("resumo", ""),
            area=classificar_area(
                doc.get("area", ""), doc.get("titulo", ""),
                doc.get("resumo", ""),
            ),
            ano=int(doc.get("ano", 0) or 0),
            tokens=tokens,
            vetor=vetor,
            topico=topico,
        ))
        setattr(trabalhos[-1], "fonte", doc.get("fonte", ""))

    estado.trabalhos = trabalhos
    estado.modelo_topicos = modelo
    estado.motor = MotorRecomendacao(trabalhos)
    print(f"[OK] Motor preparado com {len(trabalhos)} trabalhos e "
          f"{modelo.n_topicos} tópicos.", file=sys.stderr)

app = FastAPI(title="Recomendador de Temas de TCC — API da APS")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.on_event("startup")
def _inicializar() -> None:
    preparar_motor()


@app.get("/")
def status() -> dict:
    """Verificação rápida de que o servidor está no ar."""
    return {
        "status": "ok",
        "trabalhos_carregados": len(estado.trabalhos),
        "topicos": estado.modelo_topicos.n_topicos if estado.modelo_topicos else 0,
    }


@app.get("/areas")
def listar_areas() -> list[str]:
    areas = sorted({t.area for t in estado.trabalhos if t.area})
    return areas


@app.get("/estatisticas")
def estatisticas() -> dict:
    contagem: dict[str, int] = {}
    for t in estado.trabalhos:
        area = t.area or "Outras"
        contagem[area] = contagem.get(area, 0) + 1

    por_area = [
        {"area": area, "quantidade": n}
        for area, n in sorted(
            contagem.items(), key=lambda par: par[1], reverse=True
        )
    ]
    return {
        "total": len(estado.trabalhos),
        "por_area": por_area,
    }


@app.get("/buscar", response_model=list[TrabalhoResposta])
def buscar(
    q: str = Query("", description="texto para buscar no título"),
    area: str = Query("", description="filtrar por área (opcional)"),
    limite: int = Query(20, ge=1, le=100),
) -> list[TrabalhoResposta]:
    termo = q.lower().strip()
    resultados = []
    for t in estado.trabalhos:
        if termo and termo not in t.titulo.lower():
            continue
        if area and area.lower() != t.area.lower():
            continue
        resultados.append(TrabalhoResposta(
            id=t.id, titulo=t.titulo, resumo=t.resumo, area=t.area,
            ano=t.ano, fonte=getattr(t, "fonte", ""),
        ))
        if len(resultados) >= limite:
            break
    return resultados


@app.get("/recomendar", response_model=list[RecomendacaoResposta])
def recomendar(
    id: str = Query(..., description="id do trabalho de referência"),
    k: int = Query(5, ge=1, le=20),
) -> list[RecomendacaoResposta]:
    alvo = next((t for t in estado.trabalhos if t.id == id), None)
    if alvo is None:
        return []

    area_alvo = (alvo.area or "").strip().lower()

    avaliados: list[tuple[float, Trabalho]] = []
    for t in estado.trabalhos:
        if t.id == alvo.id:
            continue  

        s_conteudo = similaridade_cosseno(alvo.vetor, t.vetor)
        
        area_t = (t.area or "").strip().lower()
        if area_alvo and area_t == area_alvo:
            bonus_area = 0.35  # mesma grande área
        else:
            bonus_area = 0.0

        score_final = s_conteudo + bonus_area
        
        if score_final <= 0.0:
            continue

        avaliados.append((score_final, t))

    avaliados.sort(key=lambda par: par[0], reverse=True)
    melhores = avaliados[:k]

    return [
        RecomendacaoResposta(
            titulo=t.titulo, area=t.area, ano=t.ano,
            score=round(score, 4), fonte=getattr(t, "fonte", ""),
        )
        for score, t in melhores
    ]
