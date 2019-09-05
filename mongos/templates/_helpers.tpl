{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "mongos.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "mongos.fullname" -}}
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
{{- define "mongos.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Common labels
*/}}
{{- define "mongos.labels" -}}
app.kubernetes.io/name: {{ include "mongos.name" . }}
helm.sh/chart: {{ include "mongos.chart" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- with .Values.extraLabels }}
{{ toYaml . }}
{{- end }}
{{- end -}}

{{- define "mongos.podDefaultAffinity" -}}
{{- if .Values.podAntiAffinity.hard -}}
podAntiAffinity:
  requiredDuringSchedulingIgnoredDuringExecution:
  - labelSelector:
      matchLabels:
        app.kubernetes.io/name: {{ include "mongos.name" . }}
        app.kubernetes.io/instance: {{ .Release.Name }}
    topologyKey: {{ default "kubernetes.io/hostname" .Values.podAntiAffinity.topologyKey | quote }}
{{- else -}}
podAntiAffinity:
  preferredDuringSchedulingIgnoredDuringExecution:
  - weight: 50
    podAffinityTerm:
      labelSelector:
        matchLabels:
          app.kubernetes.io/name: {{ include "mongos.name" . }}
          app.kubernetes.io/instance: {{ .Release.Name }}
      topologyKey: {{ default "kubernetes.io/hostname" .Values.podAntiAffinity.topologyKey | quote }}
{{- end -}}
{{- end -}}

{{/*
Get the name for the metrics secret.
*/}}
{{- define "mongos.metricsSecret" -}}
{{- if .Values.auth.existingMetricsSecret -}}
{{- .Values.auth.existingMetricsSecret -}}
{{- else -}}
{{- include "mongos.fullname" . -}}-metrics
{{- end -}}
{{- end -}}

{{/*
Get the name for the key secret.
*/}}
{{- define "mongos.keySecret" -}}
{{- if .Values.auth.existingKeySecret -}}
{{- .Values.auth.existingKeySecret -}}
{{- else -}}
{{- include "mongos.fullname" . -}}-keyfile
{{- end -}}
{{- end -}}

{{/*
Get the FQDN suffix.
*/}}
{{- define "mongos.suffixFQDN" -}}
{{- if .Values.mongos.suffixFQDN -}}
{{- .Values.mongos.suffixFQDN -}}
{{- else -}}
{{- include "mongos.fullname" . -}}.{{ .Release.Namespace }}.svc
{{- end -}}
{{- end -}}

{{/*
Get the announce address.
*/}}
{{- define "mongos.announce" -}}
{{- $fullName := include "mongos.fullname" . -}}
{{- $suffixFQDN := include "mongos.suffixFQDN" . -}}
{{- $replicas := int .Values.replicas -}}
{{- $dbport := int .Values.mongos.port -}}
{{- range $i := until $replicas -}}
{{- if gt $i 0 -}},{{- end -}}
{{ $fullName }}-{{ $i }}.{{ $suffixFQDN }}:{{ $dbport }}
{{- end -}}
{{- end -}}
