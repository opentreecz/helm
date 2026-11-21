{{/*
Expand the name of the chart.
*/}}
{{- define "openrepo.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "openrepo.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "openrepo.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "openrepo.labels" -}}
helm.sh/chart: {{ include "openrepo.chart" . }}
{{ include "openrepo.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "openrepo.selectorLabels" -}}
app.kubernetes.io/name: {{ include "openrepo.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "openrepo.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "openrepo.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Container image reference.
*/}}
{{- define "openrepo.image" -}}
{{- printf "%s:%s" .Values.image.repository (.Values.image.tag | default .Chart.AppVersion) -}}
{{- end }}

{{/*
Selector labels for a given component: include "openrepo.componentSelectorLabels" (dict "ctx" . "component" "web")
*/}}
{{- define "openrepo.componentSelectorLabels" -}}
{{ include "openrepo.selectorLabels" .ctx }}
app.kubernetes.io/component: {{ .component }}
{{- end }}

{{- define "openrepo.componentLabels" -}}
{{ include "openrepo.labels" .ctx }}
app.kubernetes.io/component: {{ .component }}
{{- end }}

{{- define "openrepo.secretName" -}}
{{- include "openrepo.fullname" . }}
{{- end }}

{{- define "openrepo.postgresql.fullname" -}}
{{- printf "%s-postgresql" (include "openrepo.fullname" .) | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "openrepo.redis.fullname" -}}
{{- printf "%s-redis" (include "openrepo.fullname" .) | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Public domain.
*/}}
{{- define "openrepo.domain" -}}
{{- if .Values.openrepo.domain }}
{{- .Values.openrepo.domain }}
{{- else if and .Values.ingress.enabled .Values.ingress.hosts }}
{{- (first .Values.ingress.hosts).host }}
{{- else }}
{{- "localhost:8080" }}
{{- end }}
{{- end }}

{{/*
ALLOWED_HOSTS additions: user values plus in-cluster Service names so other
workloads (e.g. openrepo-sync) can call the API via the Service.
*/}}
{{- define "openrepo.allowedHosts" -}}
{{- $svc := include "openrepo.fullname" . -}}
{{- $ns := .Release.Namespace -}}
{{- $hosts := list $svc (printf "%s.%s" $svc $ns) (printf "%s.%s.svc" $svc $ns) (printf "%s.%s.svc.cluster.local" $svc $ns) -}}
{{- if .Values.ingress.enabled }}
{{- range .Values.ingress.hosts }}
{{- $hosts = append $hosts .host }}
{{- end }}
{{- end }}
{{- $hosts = concat $hosts .Values.openrepo.allowedHosts -}}
{{- join "," (uniq $hosts) }}
{{- end }}

{{/*
CSRF trusted origins (space separated).
*/}}
{{- define "openrepo.csrfTrustedOrigins" -}}
{{- if .Values.openrepo.csrfTrustedOrigins }}
{{- join " " .Values.openrepo.csrfTrustedOrigins }}
{{- else if .Values.ingress.enabled }}
{{- $tlsHosts := list }}
{{- range .Values.ingress.tls }}
{{- $tlsHosts = concat $tlsHosts .hosts }}
{{- end }}
{{- $origins := list }}
{{- range .Values.ingress.hosts }}
{{- $origins = append $origins (printf "%s://%s" (ternary "https" "http" (has .host $tlsHosts)) .host) }}
{{- end }}
{{- join " " $origins }}
{{- end }}
{{- end }}

{{/*
Return a value from the chart Secret if it already exists in the cluster,
otherwise the provided value or a random one.
Usage: include "openrepo.secretValue" (dict "ctx" . "key" "secret-key" "value" .Values.x "length" 50)
*/}}
{{- define "openrepo.secretValue" -}}
{{- if .value }}
{{- .value }}
{{- else }}
{{- $existing := lookup "v1" "Secret" .ctx.Release.Namespace (include "openrepo.secretName" .ctx) }}
{{- if and $existing (hasKey $existing.data .key) }}
{{- index $existing.data .key | b64dec }}
{{- else }}
{{- randAlphaNum (int .length) }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Database password secret reference.
*/}}
{{- define "openrepo.dbPasswordSecretName" -}}
{{- if and (not .Values.postgresql.enabled) .Values.externalDatabase.existingSecret }}
{{- .Values.externalDatabase.existingSecret }}
{{- else }}
{{- include "openrepo.secretName" . }}
{{- end }}
{{- end }}

{{- define "openrepo.dbPasswordSecretKey" -}}
{{- if and (not .Values.postgresql.enabled) .Values.externalDatabase.existingSecret }}
{{- .Values.externalDatabase.existingSecretPasswordKey }}
{{- else }}
{{- "postgres-password" }}
{{- end }}
{{- end }}

{{/*
Environment shared by django, worker and beat.
*/}}
{{- define "openrepo.env" -}}
- name: OPENREPO_SECRET_KEY
  valueFrom:
    secretKeyRef:
      name: {{ default (include "openrepo.secretName" .) .Values.openrepo.existingSecret }}
      key: {{ ternary .Values.openrepo.existingSecretKey "secret-key" (not (empty .Values.openrepo.existingSecret)) }}
- name: OPENREPO_DB_TYPE
  value: postgresql
{{- if .Values.postgresql.enabled }}
- name: OPENREPO_PG_HOSTNAME
  value: {{ include "openrepo.postgresql.fullname" . | quote }}
- name: OPENREPO_PG_PORT
  value: "5432"
- name: OPENREPO_PG_DATABASE
  value: {{ .Values.postgresql.auth.database | quote }}
- name: OPENREPO_PG_USERNAME
  value: {{ .Values.postgresql.auth.username | quote }}
{{- else }}
- name: OPENREPO_PG_HOSTNAME
  value: {{ required "externalDatabase.host is required when postgresql.enabled=false" .Values.externalDatabase.host | quote }}
- name: OPENREPO_PG_PORT
  value: {{ .Values.externalDatabase.port | quote }}
- name: OPENREPO_PG_DATABASE
  value: {{ .Values.externalDatabase.database | quote }}
- name: OPENREPO_PG_USERNAME
  value: {{ .Values.externalDatabase.username | quote }}
- name: OPENREPO_PG_CONN_MAX_AGE
  value: {{ .Values.externalDatabase.connMaxAge | quote }}
{{- end }}
- name: OPENREPO_PG_PASSWORD
  valueFrom:
    secretKeyRef:
      name: {{ include "openrepo.dbPasswordSecretName" . }}
      key: {{ include "openrepo.dbPasswordSecretKey" . }}
- name: OPENREPO_REDIS_URL
{{- if .Values.redis.enabled }}
  value: {{ printf "redis://%s:6379/0" (include "openrepo.redis.fullname" .) | quote }}
{{- else if .Values.externalRedis.existingSecret }}
  valueFrom:
    secretKeyRef:
      name: {{ .Values.externalRedis.existingSecret }}
      key: {{ .Values.externalRedis.existingSecretUrlKey }}
{{- else }}
  valueFrom:
    secretKeyRef:
      name: {{ include "openrepo.secretName" . }}
      key: redis-url
{{- end }}
- name: OPENREPO_DOMAIN
  value: {{ include "openrepo.domain" . | quote }}
- name: OPENREPO_ALLOWED_HOSTS
  value: {{ include "openrepo.allowedHosts" . | quote }}
{{- with include "openrepo.csrfTrustedOrigins" . }}
- name: OPENREPO_CSRF_TRUSTED_ORIGINS
  value: {{ . | quote }}
{{- end }}
- name: OPENREPO_DEBUG
  value: {{ ternary "TRUE" "FALSE" .Values.openrepo.debug | quote }}
- name: OPENREPO_LOGLEVEL
  value: {{ .Values.openrepo.logLevel | quote }}
- name: OPENREPO_MAX_UPLOAD_SIZE
  value: {{ .Values.openrepo.maxUploadSize | int64 | quote }}
{{- range $name, $value := .Values.openrepo.env }}
- name: {{ $name }}
  value: {{ $value | quote }}
{{- end }}
{{- with .Values.openrepo.extraEnv }}
{{ toYaml . }}
{{- end }}
{{- end }}

{{/*
Checksum of user-supplied secret inputs (generated values are excluded so the
checksum is stable between install and upgrade).
*/}}
{{- define "openrepo.secretChecksum" -}}
{{- list .Values.openrepo.secretKey .Values.openrepo.existingSecret .Values.postgresql.auth.password .Values.externalDatabase .Values.externalRedis | toJson | sha256sum }}
{{- end }}
