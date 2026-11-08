import math
from collections import Counter

Vetor = dict[str, float]


class VetorizadorTFIDF:

    def __init__(self) -> None:
        self.idf: dict[str, float] = {}
        self.vocabulario: list[str] = []
        self._ajustado = False

    def ajustar(self, documentos_tokens: list[list[str]]) -> "VetorizadorTFIDF":
        n_docs = len(documentos_tokens)
        document_frequency: Counter[str] = Counter()
        for tokens in documentos_tokens:
            for termo in set(tokens):
                document_frequency[termo] += 1

        self.idf = {
            termo: math.log((1 + n_docs) / (1 + df)) + 1.0
            for termo, df in document_frequency.items()
        }
        self.vocabulario = sorted(self.idf.keys())
        self._ajustado = True
        return self

    def transformar_documento(self, tokens: list[str]) -> Vetor:
        if not self._ajustado:
            raise RuntimeError("Vetorizador não foi ajustado (chame .ajustar()).")
        if not tokens:
            return {}

        contagem = Counter(tokens)
        total = len(tokens)
        vetor: Vetor = {}
        for termo, freq in contagem.items():
            idf = self.idf.get(termo)
            if idf is None:  
                continue
            tf = freq / total
            vetor[termo] = tf * idf

        return normalizar_l2(vetor)

    def ajustar_transformar(
        self, documentos_tokens: list[list[str]]
    ) -> list[Vetor]:
        self.ajustar(documentos_tokens)
        return [self.transformar_documento(t) for t in documentos_tokens]


def normalizar_l2(vetor: Vetor) -> Vetor:
    norma = math.sqrt(sum(v * v for v in vetor.values()))
    if norma == 0:
        return dict(vetor)
    return {termo: v / norma for termo, v in vetor.items()}


def similaridade_cosseno(a: Vetor, b: Vetor) -> float:
    if not a or not b:
        return 0.0
    if len(a) > len(b):
        a, b = b, a
    produto = 0.0
    for termo, peso in a.items():
        outro = b.get(termo)
        if outro is not None:
            produto += peso * outro
    return produto


def centroide(vetores: list[Vetor]) -> Vetor:
    if not vetores:
        return {}
    acumulado: Vetor = {}
    for vetor in vetores:
        for termo, peso in vetor.items():
            acumulado[termo] = acumulado.get(termo, 0.0) + peso
    n = len(vetores)
    medio = {termo: peso / n for termo, peso in acumulado.items()}
    return normalizar_l2(medio)
