{{/*
Expand the name of the chart.
*/}}
{{- define "openrepo-sync.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "openrepo-sync.fullname" -}}
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
{{- define "openrepo-sync.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "openrepo-sync.labels" -}}
helm.sh/chart: {{ include "openrepo-sync.chart" . }}
{{ include "openrepo-sync.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "openrepo-sync.selectorLabels" -}}
app.kubernetes.io/name: {{ include "openrepo-sync.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "openrepo-sync.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "openrepo-sync.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Container image reference. Release images are tagged "v<appVersion>".
*/}}
{{- define "openrepo-sync.image" -}}
{{- $tag := .Values.image.tag | default (printf "v%s" .Chart.AppVersion) -}}
{{- printf "%s:%s" .Values.image.repository $tag -}}
{{- end }}

{{/*
Name of the Secret holding the OpenRepo API key.
*/}}
{{- define "openrepo-sync.secretName" -}}
{{- default (include "openrepo-sync.fullname" .) .Values.openrepo.existingSecret }}
{{- end }}

{{/*
Name of the ConfigMap holding config.yaml.
*/}}
{{- define "openrepo-sync.configConfigMapName" -}}
{{- default (printf "%s-config" (include "openrepo-sync.fullname" .)) .Values.existingConfigConfigMap }}
{{- end }}

{{/*
Name of the ConfigMap holding project files.
*/}}
{{- define "openrepo-sync.projectsConfigMapName" -}}
{{- default (printf "%s-projects" (include "openrepo-sync.fullname" .)) .Values.existingProjectsConfigMap }}
{{- end }}

{{/*
Pod spec shared by the Deployment and the CronJob.
*/}}
{{- define "openrepo-sync.podSpec" -}}
{{- with .Values.imagePullSecrets }}
imagePullSecrets:
  {{- toYaml . | nindent 2 }}
{{- end }}
serviceAccountName: {{ include "openrepo-sync.serviceAccountName" . }}
securityContext:
  {{- toYaml .Values.podSecurityContext | nindent 2 }}
containers:
  - name: {{ .Chart.Name }}
    securityContext:
      {{- toYaml .Values.securityContext | nindent 6 }}
    image: {{ include "openrepo-sync.image" . | quote }}
    imagePullPolicy: {{ .Values.image.pullPolicy }}
    args:
      {{- if eq .Values.mode "schedule" }}
      - --schedule
      {{- end }}
      - --config
      - /config/config.yaml
      - --projects
      - /projects
      {{- range .Values.extraArgs }}
      - {{ . | quote }}
      {{- end }}
    env:
      - name: OPENREPO_API_URL
        value: {{ .Values.openrepo.apiUrl | quote }}
      - name: OPENREPO_API_KEY
        valueFrom:
          secretKeyRef:
            name: {{ include "openrepo-sync.secretName" . }}
            key: {{ .Values.openrepo.existingSecretKey }}
      - name: RUST_LOG
        value: {{ .Values.logLevel | quote }}
      - name: TZ
        value: {{ .Values.timezone | quote }}
      - name: HOME
        value: /home/openrepo
      {{- with .Values.extraEnv }}
      {{- toYaml . | nindent 6 }}
      {{- end }}
    {{- with .Values.extraEnvFrom }}
    envFrom:
      {{- toYaml . | nindent 6 }}
    {{- end }}
    resources:
      {{- toYaml .Values.resources | nindent 6 }}
    volumeMounts:
      - name: config
        mountPath: /config
        readOnly: true
      - name: projects
        mountPath: /projects
        readOnly: true
      - name: tmp
        mountPath: /tmp
      - name: home
        mountPath: /home/openrepo
      {{- with .Values.volumeMounts }}
      {{- toYaml . | nindent 6 }}
      {{- end }}
volumes:
  - name: config
    configMap:
      name: {{ include "openrepo-sync.configConfigMapName" . }}
  - name: projects
    configMap:
      name: {{ include "openrepo-sync.projectsConfigMapName" . }}
  - name: tmp
    emptyDir:
      {{- with .Values.downloadVolume.medium }}
      medium: {{ . }}
      {{- end }}
      {{- with .Values.downloadVolume.sizeLimit }}
      sizeLimit: {{ . }}
      {{- end }}
  - name: home
    emptyDir: {}
  {{- with .Values.volumes }}
  {{- toYaml . | nindent 2 }}
  {{- end }}
{{- with .Values.nodeSelector }}
nodeSelector:
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- with .Values.affinity }}
affinity:
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- with .Values.tolerations }}
tolerations:
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- end }}

{{/*
Pod annotations including checksums so config changes roll the pod.
*/}}
{{- define "openrepo-sync.podAnnotations" -}}
checksum/config: {{ include (print $.Template.BasePath "/configmap.yaml") . | sha256sum }}
checksum/secret: {{ include (print $.Template.BasePath "/secret.yaml") . | sha256sum }}
{{- with .Values.podAnnotations }}
{{ toYaml . }}
{{- end }}
{{- end }}

{{/*
Effective project map (file key → project definition), returned as YAML:
bundled projects from the chart's projects/ directory (minus exclusions),
overlaid with .Values.projects. A null entry in .Values.projects removes a
project of the same key.
*/}}
{{- define "openrepo-sync.projects" -}}
{{- $projects := dict }}
{{- $bundled := .Values.bundledProjects }}
{{- if $bundled.enabled }}
{{- range $path, $_ := .Files.Glob "projects/*.yaml" }}
{{- $key := base $path | trimSuffix ".yaml" }}
{{- $project := $.Files.Get $path | fromYaml }}
{{- if not (or (has $key $bundled.exclude) (has $project.name $bundled.exclude)) }}
{{- if $bundled.repoUid }}
{{- $_ := set $project "repo_uid" $bundled.repoUid }}
{{- end }}
{{- $_ := set $projects $key $project }}
{{- end }}
{{- end }}
{{- end }}
{{- range $key, $project := .Values.projects }}
{{- if $project }}
{{- $_ := set $projects $key $project }}
{{- else }}
{{- $_ := unset $projects $key }}
{{- end }}
{{- end }}
{{- toYaml $projects }}
{{- end }}
