$demo = @"
# Perte de poids progressive
Déficit calorique modéré (~300–500 kcal/j), protéines 1.2–1.6 g/kg/j,
fibres 25–35 g/j, hydratation suffisante, + activité physique régulière.
Surveillance : poids hebdo, tour de taille, niveau d’énergie.
"@
$bytes = $utf8.GetBytes($demo)
$demo64 = [Convert]::ToBase64String($bytes)

docker compose -f ..\docker-compose.yml exec api sh -lc "mkdir -p cours && echo $demo64 | base64 -d > cours/demo.md && sed -n '1,3p' cours/demo.md"
