# Patching (SSM Patch Manager)

## Configuration

- **Baseline** : Ubuntu, priorite Required + Important, approbation apres 7 jours
- **Fenetre de maintenance** : dimanche 3h00 AM EST (8h00 UTC)
- **Duree** : 3 heures
- **Operation** : Install avec reboot si necessaire
- **Concurrence** : 50% des instances a la fois

## Selection

Basee sur le tag `Environment` (development ou production).

## Processus

1. SSM scanne les instances selon la baseline
2. Dimanche 3h AM : installation automatique des patches approuves
3. Reboot si necessaire
4. Instances non-conformes signalees dans Security Hub
