import re

AREAS_CONHECIMENTO: list[tuple[str, tuple[str, ...]]] = [
    ("Ciências Agrárias", (
        "agronegocio", "agricultur", "agronom", "veterinari", "zootecn",
        "cultivo", "lavoura", "pecuaria", "aquicultur", "fitossanit",
        "nematoide", "safra", "irrigacao", "solo", "adubacao", "fertiliz",
        "plantio", "soja", "milho", "cafe", "cana-de-acucar", "cana de acucar",
        "horticultur", "floresta", "reflorestamento", "silvicultur",
        "bovino", "suino", "frango", "avicultur", "leiteir", "pastagem",
        "praga", "semente", "agroecolog", "agroflorest", "colheita",
        "grao", "hortalica", "fruticultur", "alevino", "peixe", "pescado",
        "piscicultur", "estocagem", "micorriz", "mudas", "angico",
    )),
    ("Ciências da Saúde", (
        "saude", "medicina", "medico", "enfermagem", "odontolog", "farmac",
        "clinic", "doenca", "paciente", "cancer", "tumor", "vascular",
        "neurolog", "cardio", "nutricao humana", "fisioterap",
        "epidemiolog", "cirurg", "arbovirus",
        "antropometric", "imunolog", "patolog", "obstetr", "pediatr",
        "psiquiatr", "oncolog", "vacina", "encefalic", "metabon",
        "microbiota", "micose", "neuromodulacao", "neuropsico",
        "sifilis", "dengue", "hepatite", "hiv", "tuberculose", "diabetes",
        "obesidade", "celiac", "probiotico", "fonoaudiolog", "disfonia",
        "renal", "sanguine", "ovarios policisticos", "hospitalar",
        "terapia fotodinamica", "serotonin", "eletromiograf",
    )),
    ("Engenharias", (
        "engenharia", "estrutural", "argamassa", "concreto",
        "mecanica", "eletrica", "hidraulic", "metalurg",
        "soldagem", "manufatur", "saneamento", "pavimento",
        "geotecnic", "construcao civil", "alvenaria", "edifici", "obra",
        "predial", "lean construction", "bim ", "reservatorio",
        "aterro", "lixiviado", "lavra", "pedreira", "granito",
        "telecomunicac", "redes optica", "fiber laser", "nanoparticula",
        "nano estrutura", "nanocomposit", "nanomaterial", "calibracao",
        "pirometro", "petroleo", "reservatorios de oleo", "eor",
    )),
    ("Ciências Exatas e da Terra", (
        "matematic", "fisica", "quimica", "estatistic", "geolog",
        "astronom", "astrofisic", "computac", "algoritmo", "software",
        "rede neural", "redes neurais", "sistema distribuido",
        "sistemas distribuidos", "inteligencia artificial",
        "aprendizado de maquina", "banco de dados", "cadeias de markov",
        "meteorolog", "espectroscop", "estrela", "solar", "exoplaneta",
        "orbita", "gravitacional", "autogravitante", "lyapunov",
        "jupiter", "jupiteres", "planeta", "celeste",
        "numeros complexos", "numeros fuzzy", "logica", "geometria",
        "estratigraf", "sediment", "bacia do", "precipitacao",
        "satelite", "climatic", "laser", "optic", "supercondutor",
        "transformada", "codigos corretores", "codigos de bloco",
        "ontolog", "semantic", "modelagem matematica", "termodinamic",
        "thermodynamic", "molecular thermodynamic", "biofuel",
        "quantum dot", "eletroquimic", "eletrossintese", "tiossulfonato",
        "dea ", "envoltoria de dados", "forecast", "energetic",
        "magnetic", "coercividade", "turbulent", "mode-locked",
        "product lines", "source code",
    )),
    ("Ciências Biológicas", (
        "biolog", "ecolog", "genetic", "microbiolog", "botanic", "zoolog",
        "biodiversidade", "bioprospec", "fisiolog",
        "ecossistema", "fauna", "flora", "palmeira", "bacillus",
        "levedura", "rotifero", "arvore", "planta medicinal",
    )),
    ("Ciências Sociais Aplicadas", (
        "direito", "juridic", "administracao", "economia", "economic",
        "contabil", "marketing", "financ", "imobiliari",
        "tratados internacionais", "jurisdicao",
        "agencias reguladoras", "politica publica", "politicas publicas",
        "turismo", "comunicacao social", "jornalismo", "incorporadora",
        "empreendedor", "gestao de projetos", "planejamento estrategico",
        "gestao", "mercado", "tributa", "tributo", "fundos",
        "mercado de capitais", "museolog", "bibliometria", "servqual",
        "gamificacao", "metodologias ageis", "okr", "branding",
        "transferencia de renda", "seguranca publica",
    )),
    ("Ciências Humanas", (
        "historia", "filosofia", "sociolog", "antropolog", "psicolog",
        "educacao", "ensino", "pedagog", "arqueolog", "etnografi",
        "ciencia politica", "analise de discurso", "geografia",
        "memoria", "religios", "deslocados internos", "direitos humanos",
        "conhecimento escolar", "aprendizagem", "fenomenolog",
        "estruturalismo", "letramento", "didatic", "tortura",
        "facccoes criminosas", "faccoes criminosas", "marxismo",
    )),
    ("Linguística, Letras e Artes", (
        "linguistic", "literatura", "literari", "idioma", "traducao",
        "musica", "teatro", "cinema", "artes visuais", "artistic",
        "poesia", "poetic", "narrativa", "anchieta", "ondjaki",
        "antropofagic", "barroco", "audiodescricao", "quadrinho",
        "quadriniza", "lingua estrangeira", "lingua",
    )),
]


def _sem_acento(texto: str) -> str:
    tabela = str.maketrans(
        "áàâãäéèêëíìîïóòôõöúùûüçÁÀÂÃÄÉÈÊËÍÌÎÏÓÒÔÕÖÚÙÛÜÇ",
        "aaaaaeeeeiiiiooooouuuucAAAAAEEEEIIIIOOOOOUUUUC",
    )
    return texto.translate(tabela)

_AREAS_REGEX: list[tuple[str, re.Pattern[str]]] = []
for _nome, _palavras in AREAS_CONHECIMENTO:
    _alternativas = "|".join(re.escape(_sem_acento(p)) for p in _palavras)
    _AREAS_REGEX.append((_nome, re.compile(r"\b(?:" + _alternativas + r")")))


def classificar_area(area_original: str, titulo: str = "", resumo: str = "") -> str:
    texto = _sem_acento(f"{area_original} {titulo} {resumo}".lower())
    for nome_area, regex in _AREAS_REGEX:
        if regex.search(texto):
            return nome_area
    return "Outras"
