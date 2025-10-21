# app/services/prompting.py
import os
MAX_CTX = int(os.getenv("RAG_MAX_TOKENS_CONTEXT", "2000"))

def build_prompt(profil, question: str, passages: list) -> str:
    # Coupe le contexte si trop long (sécurité)
    context_blocks = []
    total_chars = 0
    for p in passages:
        t = p["text"].strip()
        if not t: continue
        if total_chars + len(t) > MAX_CTX: break
        context_blocks.append(f"[Source: {p['source']} / chunk:{p['chunk_id']}]\n{t}\n")
        total_chars += len(t)

    context = "\n---\n".join(context_blocks)
    # System + consignes
    system = (
        "Tu es un assistant de consultation diététique destiné aux professionnels. "
        "Tu n’émets ni diagnostic ni prescription médicale. Tu utilises strictement "
        "le contexte fourni (extraits des cours) et signales toute incertitude. "
        "Tu dois produire un brouillon marqué 'draft' nécessitant validation humaine."
    )
    patient = (
        f"Profil patient: {profil.age} ans, {profil.sexe}, {profil.taille_cm} cm, "
        f"{profil.poids_kg} kg, activité {profil.activite}. "
        f"Objectifs: {', '.join(profil.objectifs)}. "
        f"Allergies: {', '.join(profil.allergies)}. "
        f"Pathologies: {', '.join(profil.pathologies)}. "
        f"Médicaments: {', '.join(profil.medicaments)}."
    )
    user = (
        f"<<CONTEXTE_COUPS>>\n{context}\n<</CONTEXTE_COUPS>>\n\n"
        f"Question du patient: {question}\n\n"
        "Tâches:\n"
        "1) Vérifier drapeaux rouges; si risque sérieux → proposer orientation et STOP.\n"
        "2) Estimer besoins (formule + justification brève), macros.\n"
        "3) Proposer un plan alimentaire (7 jours) avec alternatives et liste de courses.\n"
        "4) Donner 3–5 points d’éducation thérapeutique.\n"
        "5) Lister hypothèses/incertitudes et éléments marqués '⛳ Validation'.\n"
        "Contraintes: ton clair, unités SI, pas de prescriptions."
    )
    # Format attendu pour /api/generate d’Ollama (prompt unique)
    return f"<<SYS>>{system}<</SYS>>\n{patient}\n\n{user}"