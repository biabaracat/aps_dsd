import re
import unicodedata

STOPWORDS_PT: frozenset[str] = frozenset(
    """
    a o e os as um uma uns umas de do da dos das em no na nos nas por para
    com sem sob sobre entre ate ate' apos antes que qual quais quando onde
    como porque pois porem porem entao assim ja nao sim se ou nem mais menos
    muito muita muitos muitas pouco pouca poucos poucas todo toda todos todas
    este esta estes estas esse essa esses essas aquele aquela aqueles aquelas
    isto isso aquilo seu sua seus suas meu minha nosso nossa dele dela deles
    delas ao aos a's ser estar ter haver foi sao era eram tem tinha havia
    ha sera serao pelo pela pelos pelas num numa dum duma e' tambem apenas
    ainda cada tal tais qualquer atraves mediante conforme segundo cujo cuja
    lhe lhes te vos nos eu tu ele ela eles elas voce voces me mim comigo
    """.split()
)

_SUFIXOS = (
    "acoes", "acao", "amento", "imento", "ancia", "encia", "mente",
    "izacao", "izar", "ismo", "ista", "avel", "ivel", "dade",
    "coes", "cao", "oes", "ais", "eis", "ies", "ues",
    "ando", "endo", "indo", "ados", "adas", "idos", "idas",
    "ador", "ora", "aria", "eria",
    "ar", "er", "ir", "os", "as", "es", "ns", "am", "em",
    "a", "o", "e", "s",
)

_RE_URL = re.compile(r"https?://\S+|www\.\S+")
_RE_NAO_ALFANUM = re.compile(r"[^a-z0-9\s]")
_RE_ESPACOS = re.compile(r"\s+")
_RE_SO_DIGITOS = re.compile(r"^\d+$")


def remover_acentos(texto: str) -> str:
    nfkd = unicodedata.normalize("NFKD", texto)
    return "".join(c for c in nfkd if not unicodedata.combining(c))


def limpar_texto(texto: str) -> str:
    texto = texto.lower()
    texto = _RE_URL.sub(" ", texto)
    texto = remover_acentos(texto)
    texto = _RE_NAO_ALFANUM.sub(" ", texto)
    return _RE_ESPACOS.sub(" ", texto).strip()


def tokenizar(texto: str) -> list[str]:
    if not texto:
        return []
    return texto.split(" ")


def remover_stopwords(tokens: list[str], tamanho_minimo: int = 3) -> list[str]:
    resultado = []
    for tok in tokens:
        if len(tok) < tamanho_minimo:
            continue
        if tok in STOPWORDS_PT:
            continue
        if _RE_SO_DIGITOS.match(tok):
            continue
        resultado.append(tok)
    return resultado


def stem(token: str) -> str:
    for sufixo in _SUFIXOS:
        if token.endswith(sufixo) and len(token) - len(sufixo) >= 3:
            return token[: -len(sufixo)]
    return token


def preprocessar(texto: str, aplicar_stemming: bool = True) -> list[str]:
    limpo = limpar_texto(texto)
    tokens = tokenizar(limpo)
    tokens = remover_stopwords(tokens)
    if aplicar_stemming:
        tokens = [stem(t) for t in tokens]
        tokens = [t for t in tokens if len(t) >= 3]
    return tokens
