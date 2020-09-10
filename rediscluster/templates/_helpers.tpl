{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "rediscluster.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "rediscluster.fullname" -}}
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
{{- define "rediscluster.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Common labels
*/}}
{{- define "rediscluster.labels" -}}
app.kubernetes.io/name: {{ include "rediscluster.name" . }}
helm.sh/chart: {{ include "rediscluster.chart" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- with .Values.extraLabels }}
{{ toYaml . }}
{{- end }}
{{- end -}}

{{- define "rediscluster.podDefaultAffinity" -}}
{{- $dot := index . 0 -}}
{{- $group := index . 1 -}}
{{- with $dot -}}
{{- if .Values.podAntiAffinity.hard -}}
podAntiAffinity:
  requiredDuringSchedulingIgnoredDuringExecution:
  - labelSelector:
      matchLabels:
        app.kubernetes.io/name: {{ include "rediscluster.name" . }}
        app.kubernetes.io/instance: {{ .Release.Name }}
        rediscluster/group: "{{ $group }}"
    topologyKey: {{ default "kubernetes.io/hostname" .Values.podAntiAffinity.topologyKey | quote }}
{{- else -}}
podAntiAffinity:
  preferredDuringSchedulingIgnoredDuringExecution:
  - weight: 50
    podAffinityTerm:
      labelSelector:
        matchLabels:
          app.kubernetes.io/name: {{ include "rediscluster.name" . }}
          app.kubernetes.io/instance: {{ .Release.Name }}
          rediscluster/group: "{{ $group }}"
      topologyKey: {{ default "kubernetes.io/hostname" .Values.podAntiAffinity.topologyKey | quote }}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
Create the name for the auth secret.
*/}}
{{- define "rediscluster.authSecret" -}}
{{- if .Values.auth.existingSecret -}}
{{- .Values.auth.existingSecret -}}
{{- else -}}
{{- include "rediscluster.fullname" . -}}
{{- end -}}
{{- end -}}

{{/*
Get the bus port.
*/}}
{{- define "rediscluster.busPort" -}}
{{- add 10000 (int .Values.redis.port) -}}
{{- end -}}

{{/*
Get the announce address.
*/}}
{{- define "rediscluster.announce" -}}
{{- $groups := int .Values.groups -}}
{{- $dbport := int .Values.redis.port -}}
{{- range $i := until $groups -}}
{{- with $ -}}
{{- if gt $i 0 -}},{{- end -}}
{{- include "rediscluster.fullname" . -}}-{{ $i }}-0.{{ .Release.Namespace }}.svc:{{ $dbport }}
{{- end -}}
{{- end -}}
{{- end -}}
