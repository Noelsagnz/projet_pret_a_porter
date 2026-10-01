# Synthèse des contrôles qualité et indicateurs clés

## 1. Contrôles des règles métier

| Règle métier | Résultat | Anomalies |
|---|---|---:|
| 1. Montant commande = somme des lignes | ❌ Non conforme | 99 |
| 2. Frais de livraison | ✅ Conforme | 0 |
| 3. BIENVENUE10 uniquement sur la première commande | ✅ Conforme | 0 |
| 4. Remises 30-50 % en période de soldes sur collections saisonnières | ✅ Conforme | 0 |
| 5. Paiement en 3x à partir de 100 € | ❌ Non conforme | 17 |
| 6. Date de livraison cohérente avec le statut | ✅ Conforme | 0 |
| 7. Retours et remboursements | ❌ Non conforme | 20 + 4 cas à qualifier |
| 8. Calcul de la marge brute | ✅ Conforme | 0 |

### Règle 1 — Montant total des commandes

99 commandes présentent un écart entre `montant_total` et la somme des lignes :

`quantite × prix_unitaire_facture`.

Les écarts ne semblent pas liés à un simple arrondi. Les valeurs observées montrent notamment des rapports de 0,50, 1,10 et 2,00 entre les deux montants.

Le montant source `montant_total` est conservé dans les données. Le contrôle est maintenu afin d'identifier les anomalies de la source.

### Règle 2 — Frais de livraison

Aucune anomalie détectée.

Les frais observés respectent les règles définies pour les modes Standard, Point relais et Express.

### Règle 3 — Code BIENVENUE10

Aucune utilisation de `BIENVENUE10` après la première commande d'un client.

Le contrôle vérifie l'utilisation effective du code. Il ne permet pas de vérifier si le code a été proposé puis refusé.

### Règle 4 — Promotions et soldes

Aucune anomalie détectée concernant les remises comprises entre 30 % et 50 %.

Les remises de cette plage sont limitées aux mois de janvier et juillet et aux collections saisonnières `AH24` et `PE25`.

### Règle 5 — Paiement en 3x

17 commandes utilisent le paiement en 3x avec un montant inférieur à 100 €.

Montant minimum observé : 13,30 €.

Ces commandes constituent des anomalies par rapport à la règle métier.

### Règle 6 — Livraison

Aucune anomalie détectée.

Les commandes livrées possèdent une date de livraison et les commandes non livrées n'en possèdent pas.

### Règle 7 — Retours et remboursements

Aucun retour n'a été identifié sur une commande non livrée.

Pour les remboursements avec le statut `rembourse`, 20 anomalies ont été identifiées concernant le calcul :

`quantite_retournee × prix_unitaire_facture`.

4 autres cas présentent un statut `Non renseigné` et doivent être considérés comme des cas de qualité de données distincts.

Les retours avec le statut `refuse` ne sont pas interprétés comme des anomalies de remboursement puisque le remboursement n'a pas été effectué.

### Règle 8 — Marge brute

Aucune anomalie détectée.

Le calcul respecte :

`(prix_unitaire_facture - cout_unitaire) × quantite`.

---

# 2. Contrôles Bronze → Silver → Gold

## Volumes

| Objet | Bronze | Silver | Gold |
|---|---:|---:|---:|
| Clients | 8 000 | 8 000 | 8 000 |
| Commandes | 50 000 | 49 810 | 49 810 |
| Lignes de commande | 111 095 | 111 095 | 111 095 |
| Produits | 500 | 500 | 500 |
| Retours | 6 000 | 5 821 | 5 821 |

Les écarts Bronze → Silver sur les commandes et les retours correspondent aux données rejetées.

## Réconciliation des rejets

### Commandes

`50 000 Bronze = 49 810 Silver + 190 rejets`

### Retours

`6 000 Bronze = 5 821 Silver + 179 rejets`

La réconciliation est complète.

---

# 3. Contrôle des indicateurs clés

## Chiffre d'affaires

| Couche | CA |
|---|---:|
| Bronze | 8 793 632,39 € |
| Silver | 8 793 632,39 € |
| Gold | 8 793 632,39 € |

Le chiffre d'affaires est conservé à l'identique entre les couches.

## Marge brute

| Couche | Marge brute |
|---|---:|
| Silver | 4 238 307,70 € |
| Gold | 4 238 307,70 € |

La marge brute est conservée à l'identique entre Silver et Gold.

La comparaison directe avec Bronze n'est pas réalisée car le coût unitaire nécessaire au calcul de la marge n'est pas disponible dans les données Bronze utilisées pour ce contrôle.

## Quantités vendues

| Couche | Quantité |
|---|---:|
| Bronze | 143 202 |
| Silver | 143 202 |
| Gold | 143 202 |

Les quantités vendues sont conservées à l'identique entre les couches.

---

# 4. Conclusion

Les contrôles montrent que les transformations entre Bronze, Silver et Gold conservent correctement les principaux volumes et indicateurs.

Les principales anomalies identifiées concernent les données métier sources :

- 99 commandes présentent un écart entre le montant de commande et la somme des lignes ;
- 17 commandes utilisent le paiement en 3x sous le seuil de 100 € ;
- 20 remboursements présentent un écart avec la formule attendue ;
- 4 retours avec un statut `Non renseigné` nécessitent une qualification complémentaire.

Les rejets Bronze → Silver sont quant à eux correctement réconciliés.