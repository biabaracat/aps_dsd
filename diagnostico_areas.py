import json
import os
from collections import Counter

from classificacao import classificar_area

PASTA = os.path.dirname(os.path.abspath(__file__))
CAMINHO = os.path.join(PASTA, "data", "corpus.json")


def main() -> None:
    with open(CAMINHO, encoding="utf-8") as f:
        corpus = json.load(f)

    contagem: Counter[str] = Counter()
    outras: list[tuple[str, str]] = []

    for doc in corpus:
        area = classificar_area(
            doc.get("area", ""), doc.get("titulo", ""), doc.get("resumo", ""),
        )
        contagem[area] += 1
        if area == "Outras":
            outras.append((doc.get("id", "?"), doc.get("titulo", "")))

    total = sum(contagem.values())
    print("=" * 64)
    print(f"DISTRIBUIÇÃO POR GRANDE ÁREA  (total: {total} trabalhos)")
    print("=" * 64)
    for area, n in contagem.most_common():
        pct = 100 * n / total if total else 0
        print(f"  {area:32} {n:3}  ({pct:4.1f}%)")

    print()
    print("-" * 64)
    print(f'Trabalhos em "Outras" ({len(outras)}):')
    print("-" * 64)
    for doc_id, titulo in outras:
        print(f"  [{doc_id}] {titulo[:60]}")


if __name__ == "__main__":
    main()
