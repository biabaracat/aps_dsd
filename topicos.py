from collections import Counter

from .representacao import Vetor, centroide, similaridade_cosseno


class ModeloTopicos:
    def __init__(self, limiar_similaridade: float = 0.10) -> None:
        self.limiar = limiar_similaridade
        self.centroides: list[Vetor] = []
        self.membros: list[list[int]] = []       
        self.atribuicoes: list[int] = []          
        self.termos_por_topico: list[list[str]] = []

    def ajustar(
        self,
        vetores: list[Vetor],
        documentos_tokens: list[list[str]] | None = None,
    ) -> "ModeloTopicos":
        self.centroides = []
        self.membros = []
        self.atribuicoes = []

        for idx, vetor in enumerate(vetores):
            melhor_topico = -1
            melhor_sim = self.limiar
            for t, centro in enumerate(self.centroides):
                sim = similaridade_cosseno(vetor, centro)
                if sim >= melhor_sim:
                    melhor_sim = sim
                    melhor_topico = t

            if melhor_topico == -1:
                # novo tópico
                self.centroides.append(dict(vetor))
                self.membros.append([idx])
                self.atribuicoes.append(len(self.centroides) - 1)
            else:
                self.membros[melhor_topico].append(idx)
                membros_vetores = [vetores[i] for i in self.membros[melhor_topico]]
                self.centroides[melhor_topico] = centroide(membros_vetores)
                self.atribuicoes.append(melhor_topico)

        if documentos_tokens is not None:
            self._descrever_topicos(documentos_tokens)
        return self

    def _descrever_topicos(
        self, documentos_tokens: list[list[str]], top_n: int = 8
    ) -> None:
        """Extrai os termos mais frequentes de cada tópico (rótulo do tópico)."""
        self.termos_por_topico = []
        for indices in self.membros:
            contagem: Counter[str] = Counter()
            for i in indices:
                contagem.update(documentos_tokens[i])
            termos = [termo for termo, _ in contagem.most_common(top_n)]
            self.termos_por_topico.append(termos)

    @property
    def n_topicos(self) -> int:
        return len(self.centroides)

    def tamanho_dos_topicos(self) -> list[int]:
        return [len(m) for m in self.membros]
