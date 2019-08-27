{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "mongodb.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "mongodb.fullname" -}}
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
{{- define "mongodb.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Common labels
*/}}
{{- define "mongodb.labels" -}}
app.kubernetes.io/name: {{ include "mongodb.name" . }}
helm.sh/chart: {{ include "mongodb.chart" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- with .Values.extraLabels }}
{{ toYaml . }}
{{- end }}
{{- end -}}

{{- define "mongodb.podDefaultAffinity" -}}
{{- if .Values.podAntiAffinity.hard -}}
podAntiAffinity:
  requiredDuringSchedulingIgnoredDuringExecution:
  - labelSelector:
      matchLabels:
        app.kubernetes.io/name: {{ include "mongodb.name" . }}
        app.kubernetes.io/instance: {{ .Release.Name }}
    topologyKey: {{ default "kubernetes.io/hostname" .Values.podAntiAffinity.topologyKey | quote }}
{{- else -}}
podAntiAffinity:
  preferredDuringSchedulingIgnoredDuringExecution:
  - weight: 50
    podAffinityTerm:
      labelSelector:
        matchLabels:
          app.kubernetes.io/name: {{ include "mongodb.name" . }}
          app.kubernetes.io/instance: {{ .Release.Name }}
      topologyKey: {{ default "kubernetes.io/hostname" .Values.podAntiAffinity.topologyKey | quote }}
{{- end -}}
{{- end -}}

{{/*
Get the name for the admin secret.
*/}}
{{- define "mongodb.adminSecret" -}}
{{- if .Values.auth.existingAdminSecret -}}
{{- .Values.auth.existingAdminSecret -}}
{{- else -}}
{{- include "mongodb.fullname" . -}}-admin
{{- end -}}
{{- end -}}

{{/*
Get the name for the rwany secret.
*/}}
{{- define "mongodb.rwanySecret" -}}
{{- if .Values.auth.existingRwanySecret -}}
{{- .Values.auth.existingRwanySecret -}}
{{- else -}}
{{- include "mongodb.fullname" . -}}-rwany
{{- end -}}
{{- end -}}

{{/*
Get the name for the metrics secret.
*/}}
{{- define "mongodb.metricsSecret" -}}
{{- if .Values.auth.existingMetricsSecret -}}
{{- .Values.auth.existingMetricsSecret -}}
{{- else -}}
{{- include "mongodb.fullname" . -}}-metrics
{{- end -}}
{{- end -}}

{{/*
Get the name for the key secret.
*/}}
{{- define "mongodb.keySecret" -}}
{{- if .Values.auth.existingKeySecret -}}
{{- .Values.auth.existingKeySecret -}}
{{- else -}}
{{- include "mongodb.fullname" . -}}-keyfile
{{- end -}}
{{- end -}}

{{/*
Get the FQDN suffix.
*/}}
{{- define "mongodb.suffixFQDN" -}}
{{- if .Values.mongodb.suffixFQDN -}}
{{- .Values.mongodb.suffixFQDN -}}
{{- else -}}
{{- include "mongodb.fullname" . -}}.{{ .Release.Namespace }}.svc
{{- end -}}
{{- end -}}

{{/*
Get the announce address.
*/}}
{{- define "mongodb.announce" -}}
{{- $fullName := include "mongodb.fullname" . -}}
{{- $suffixFQDN := include "mongodb.suffixFQDN" . -}}
{{- $replicas := int .Values.replicas -}}
{{- $dbport := int .Values.mongodb.port -}}
{{- range $i := until $replicas -}}
{{- if gt $i 0 -}},{{- end -}}
{{ $fullName }}-{{ $i }}.{{ $suffixFQDN }}:{{ $dbport }}
{{- end -}}
{{- end -}}
