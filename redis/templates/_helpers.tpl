{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "redis.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "redis.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- $last := .Release.Name | splitList "-" | last -}}
{{- if contains $name .Release.Name -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else if hasPrefix $last $name -}}
{{- printf "%s%s" .Release.Name (trimPrefix $last $name) | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "redis.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Common labels
*/}}
{{- define "redis.labels" -}}
app.kubernetes.io/name: {{ include "redis.name" . }}
helm.sh/chart: {{ include "redis.chart" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- with .Values.extraLabels }}
{{ toYaml . }}
{{- end }}
{{- end -}}

{{- define "redis.podDefaultAffinity" -}}
{{- if .Values.podAntiAffinity.hard -}}
podAntiAffinity:
  requiredDuringSchedulingIgnoredDuringExecution:
  - labelSelector:
      matchLabels:
        app.kubernetes.io/name: {{ include "redis.name" . }}
        app.kubernetes.io/instance: {{ .Release.Name }}
    topologyKey: {{ default "kubernetes.io/hostname" .Values.podAntiAffinity.topologyKey | quote }}
{{- else -}}
podAntiAffinity:
  preferredDuringSchedulingIgnoredDuringExecution:
  - weight: 50
    podAffinityTerm:
      labelSelector:
        matchLabels:
          app.kubernetes.io/name: {{ include "redis.name" . }}
          app.kubernetes.io/instance: {{ .Release.Name }}
      topologyKey: {{ default "kubernetes.io/hostname" .Values.podAntiAffinity.topologyKey | quote }}
{{- end -}}
{{- end -}}

{{/*
Create the name for the auth secret.
*/}}
{{- define "redis.authSecret" -}}
{{- if .Values.auth.existingSecret -}}
{{- .Values.auth.existingSecret -}}
{{- else -}}
{{- include "redis.fullname" . -}}
{{- end -}}
{{- end -}}

{{- define "redis.masterGroup" -}}
{{- .Values.masterGroupName -}}
{{- end -}}

{{/*
Get the instances announce address.
*/}}
{{- define "redis.announce" -}}
{{- $replicas := int .Values.replicas -}}
{{- $dbport := int .Values.redis.port -}}
{{- range $i := until $replicas -}}
{{- with $ -}}
{{- if gt $i 0 -}},{{- end -}}
{{- include "redis.fullname" . -}}-{{ $i }}.{{ .Release.Namespace }}.svc:{{ $dbport }}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
Get the sentinel announce address.
*/}}
{{- define "redis.sentinel.announce" -}}
{{- $replicas := int .Values.replicas -}}
{{- $dbport := int .Values.sentinel.port -}}
{{- range $i := until $replicas -}}
{{- with $ -}}
{{- if gt $i 0 -}},{{- end -}}
{{- include "redis.fullname" . -}}-{{ $i }}.{{ .Release.Namespace }}.svc:{{ $dbport }}
{{- end -}}
{{- end -}}
{{- end -}}
