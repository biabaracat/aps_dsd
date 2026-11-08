from dataclasses import dataclass, field

from .representacao import Vetor, centroide, similaridade_cosseno


@dataclass
class Trabalho:

    id: str
    titulo: str
    resumo: str
    area: str
    ano: int
    tokens: list[str] = field(default_factory=list)
    vetor: Vetor = field(default_factory=dict)
    topico: int = -1


@dataclass
class Recomendacao:

    trabalho: Trabalho
    score: float
    componentes: dict[str, float]

    def explicacao(self) -> str:
        partes = [f"{nome}={valor:.3f}" for nome, valor in self.componentes.items()]
        return f"{self.trabalho.titulo} [score={self.score:.3f}] ({', '.join(partes)})"


@dataclass
class PesosRecomendacao:

    conteudo: float = 0.55
    colaborativa: float = 0.20
    tendencia: float = 0.15
    inovacao: float = 0.10


class MotorRecomendacao:
    
    def __init__(
        self,
        trabalhos: list[Trabalho],
        pesos: PesosRecomendacao | None = None,
        limiar_similaridade: float = 0.02,
        limiar_afinidade_colaborativa: float = 0.08,
        ano_atual: int = 2026,
    ) -> None:
        self.trabalhos = trabalhos
        self.pesos = pesos or PesosRecomendacao()
        self.limiar_similaridade = limiar_similaridade
        self.limiar_afinidade_colaborativa = limiar_afinidade_colaborativa
        self.ano_atual = ano_atual
        self._tendencia_por_topico = self._calcular_tendencia_topicos()
        
    def _calcular_tendencia_topicos(self) -> dict[int, float]:
        recentes: dict[int, int] = {}
        total: dict[int, int] = {}
        for t in self.trabalhos:
            total[t.topico] = total.get(t.topico, 0) + 1
            if self.ano_atual - t.ano <= 3:
                recentes[t.topico] = recentes.get(t.topico, 0) + 1
        return {
            topico: recentes.get(topico, 0) / n if n else 0.0
            for topico, n in total.items()
        }

    def _score_inovacao(self, trabalho: Trabalho) -> float:
        idade = max(0, self.ano_atual - trabalho.ano)
        return max(0.0, 1.0 - idade / 10.0)

    def _score_colaborativo(
        self, trabalho: Trabalho, topicos_de_interesse: set[int]
    ) -> float:
        return 1.0 if trabalho.topico in topicos_de_interesse else 0.0

    def construir_perfil(self, trabalhos_do_usuario: list[Trabalho]) -> Vetor:
        return centroide([t.vetor for t in trabalhos_do_usuario])

    def recomendar(
        self,
        perfil: Vetor,
        topicos_de_interesse: set[int] | None = None,
        excluir_ids: set[str] | None = None,
        k: int = 10,
        lambda_mmr: float = 0.7,
    ) -> list[Recomendacao]:
        topicos_de_interesse = topicos_de_interesse or set()
        excluir_ids = excluir_ids or set()

        candidatos: list[Recomendacao] = []
        for trabalho in self.trabalhos:
            if trabalho.id in excluir_ids:
                continue

            s_conteudo = similaridade_cosseno(perfil, trabalho.vetor)
            if s_conteudo < self.limiar_similaridade and not topicos_de_interesse:
                continue
            s_colab = self._score_colaborativo(trabalho, topicos_de_interesse)
            if s_conteudo < self.limiar_afinidade_colaborativa:
                s_colab = 0.0
            s_tend = self._tendencia_por_topico.get(trabalho.topico, 0.0)
            s_inov = self._score_inovacao(trabalho)

            score = (
                self.pesos.conteudo * s_conteudo
                + self.pesos.colaborativa * s_colab
                + self.pesos.tendencia * s_tend
                + self.pesos.inovacao * s_inov
            )
            componentes = {
                "conteudo": s_conteudo,
                "colaborativa": s_colab,
                "tendencia": s_tend,
                "inovacao": s_inov,
            }
            candidatos.append(Recomendacao(trabalho, score, componentes))

        candidatos.sort(key=lambda r: r.score, reverse=True)

        return self._aplicar_mmr(candidatos, k, lambda_mmr)

    def _aplicar_mmr(
        self, candidatos: list[Recomendacao], k: int, lambda_mmr: float
    ) -> list[Recomendacao]:
        selecionados: list[Recomendacao] = []
        restantes = list(candidatos)

        while restantes and len(selecionados) < k:
            melhor = None
            melhor_valor = float("-inf")
            for cand in restantes:
                if not selecionados:
                    valor = cand.score
                else:
                    sim_max = max(
                        similaridade_cosseno(cand.trabalho.vetor, s.trabalho.vetor)
                        for s in selecionados
                    )
                    valor = lambda_mmr * cand.score - (1 - lambda_mmr) * sim_max
                if valor > melhor_valor:
                    melhor_valor = valor
                    melhor = cand
            selecionados.append(melhor)
            restantes.remove(melhor)

        return selecionados
