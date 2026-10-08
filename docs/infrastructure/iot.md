# IoT -> API (pipeline MQTT dev + prod)

Les diffuseurs publient sur l'unique endpoint IoT du compte Prod. Chaque flux MQTT a deux règles IoT qui se déclenchent sur chaque message : l'une appelle une Lambda qui POST vers `dev.aromaestro.com`, l'autre vers `www.aromaestro.com`. Les deux sites doivent recevoir tous les événements.

## Environnement

| | Valeur |
|---|---|
| Terraform dir | `terraform/environments/prod-iot/` |
| Compte AWS | Prod (872515273944) |
| Profil CLI | `aromaestro-prod` (backend: `aromaestro-mgmt`) |
| State S3 key | `env/prod-iot/terraform.tfstate` |
| Region | ca-central-1 |

Créé à la main, importé dans Terraform le 2026-10-05 (blocs `import` retirés après application, voir l'historique git). Les noms sont conservés tels quels, y compris la faute `iotCommanResponseToApi` : renommer forcerait un remplacement.

## Flux

| Flux | Topic | Règle dev -> Lambda | Règle prod -> Lambda | Route API |
|---|---|---|---|---|
| Shadow | `$aws/things/+/shadow/update/documents` | `shadowUpdateToLambda` -> `iotShadowToApi` | `shadowUpdateToLambdaProd` -> `iotShadowToApiProd` | `api/diffuser_mqtt_shadow` |
| Logs | `aromaestro/things/+/logs` | `deviceLogsToLambda` -> `iotLogsToApi` | `deviceLogsToLambdaProd` -> `iotLogsToApiProd` | `api/diffuser_logs` |
| Réponses de commande | `aromaestro/things/+/commands/response` | `commandResponseToLambda` -> `iotCommanResponseToApi` | `commandResponseToLambdaProd` -> `iotCommandResponseToApiProd` | `api/diffuser_mqtt_command_response` |
| Provisioning | `$aws/events/thing/+/created` | `CaptureDeviceProvisioning` -> `ProvisionDevices` | `CaptureDeviceProvisioningProd` -> `ProvisionDevicesProd` | `api/diffuser_provision` |
| Online status | `aromaestro/things/+/online_status` | `Online_Status` : republish vers `$aws/things/<thing>/shadow/update` | (aucune : le shadow déclenche les deux règles shadow) | — |

**Filtrage dev (depuis le 2026-10-08) :** les règles dev ne reçoivent que les appareils listés dans `prod-iot/dev-devices.tf` (`WHERE topic(3) = '<serial>' OR ...`, `thingName` pour le provisioning). Tous les autres diffuseurs n'arrivent qu'en prod. Pour envoyer une nouvelle carte de test en dev, ajouter son numéro de série dans la liste et faire l'`apply` **avant** de la provisionner.

Les Lambdas dev et prod d'un flux exécutent le même code (`prod-iot/lambda/<flux>/`). Seules `API_URL` et `API_KEY` diffèrent.

## Événements en échec et alertes (prod)

Les règles IoT invoquent les Lambdas en asynchrone. Pour les 4 Lambdas prod : 2 réessais, puis l'événement part dans la file SQS `prod-iot-failed-events` (conservation 14 jours) au lieu d'être perdu.

Alarmes `prod-iot-*` (`alerts.tf`) vers le topic SNS `prod-iot-alerts`, abonné à it@aromaestro.com :
- `prod-iot-<Lambda>-errors`, `-dropped`, `-destination_failures` (seuil > 0 sur 5 min) ;
- `prod-iot-failed-events-queued` : au moins un événement en attente dans la file. Inspecter, corriger côté site, puis rejouer ou purger.

Le topic est chiffré par la clé KMS `alias/prod-iot-alerts` : CloudWatch ne peut pas publier vers un topic chiffré avec `alias/aws/sns`.

## Clés API

`API_KEY` est envoyée dans l'en-tête `X-Api-Key`. La valeur prod est `AWS_IOT_LAMBDA_API_KEY` du `config.php` du site prod. Les clés sont dans `prod-iot/iot.auto.tfvars` (gitignoré, voir `iot.auto.tfvars.example`) et donc dans le state S3 chiffré. Ne jamais les committer.

Vérifier une clé sans l'afficher :

```bash
printf '%s' "$KEY" | shasum -a 256
php -r 'include "config.php"; echo hash("sha256", AWS_IOT_LAMBDA_API_KEY), "\n";'
```

## Sécurité, journalisation, indexation et domaine (`iot-security.tf`)

Importés le 2026-10-08 après l'audit de flotte :
- `Diffuser_Policy` : document dans `prod-iot/policies/diffuser-policy.json`. Toute modification crée une nouvelle version (5 au maximum, la plus ancienne non par défaut est supprimée).
- Journalisation IoT v2 au niveau ERROR via `service-role/IoTLoggingRole` (groupe `AWSIotLogsV2`).
- Indexation de flotte : REGISTRY_AND_SHADOW + connectivité STATUS. Changer un mode relance une réindexation.
- Domaine `iot.aromaestro.com` (config `aromaestro-iot`, DATA) et son certificat ACM, protégés par `prevent_destroy`. Le firmware >= 1.1.2 s'y connecte d'abord. Le CNAME de validation ACM `_b37adb6e1c3e1a423e51df2c9bc7eb85.iot` dans Cloudflare ne doit jamais être supprimé.
- Hors Terraform : certificats d'appareils (fleet provisioning) et DNS Cloudflare.

## Points connus

- Le rôle `service-role/test` d'`Online_Status` a `AWSIoTFullAccess` en plus de sa politique générée par la console. Beaucoup trop large pour un republish : à resserrer.
- Les politiques gérées par le client des rôles dev (`service-role/AWSLambda...-<uuid>`) sont attachées par ARN ; leur contenu n'est pas géré ici.
- Les log groups `/aws/lambda/*` sont créés par Lambda et ne sont pas gérés ici (rétention illimitée).
- Aucune règle n'a d'`errorAction` : un échec de Lambda n'est visible que dans ses logs CloudWatch.
