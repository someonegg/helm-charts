{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "rediscl.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "rediscl.fullname" -}}
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
{{- define "rediscl.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Common labels
*/}}
{{- define "rediscl.labels" -}}
app.kubernetes.io/name: {{ include "rediscl.name" . }}
helm.sh/chart: {{ include "rediscl.chart" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- with .Values.extraLabels }}
{{ toYaml . }}
{{- end }}
{{- end -}}

{{- define "rediscl.podDefaultAffinity" -}}
{{- $dot := index . 0 -}}
{{- $group := index . 1 -}}
{{- with $dot -}}
{{- if .Values.podAntiAffinity.hard -}}
podAntiAffinity:
  requiredDuringSchedulingIgnoredDuringExecution:
  - labelSelector:
      matchLabels:
        app.kubernetes.io/name: {{ include "rediscl.name" . }}
        app.kubernetes.io/instance: {{ .Release.Name }}
        rediscl/group: "{{ $group }}"
    topologyKey: {{ default "kubernetes.io/hostname" .Values.podAntiAffinity.topologyKey | quote }}
{{- else -}}
podAntiAffinity:
  preferredDuringSchedulingIgnoredDuringExecution:
  - weight: 50
    podAffinityTerm:
      labelSelector:
        matchLabels:
          app.kubernetes.io/name: {{ include "rediscl.name" . }}
          app.kubernetes.io/instance: {{ .Release.Name }}
          rediscl/group: "{{ $group }}"
      topologyKey: {{ default "kubernetes.io/hostname" .Values.podAntiAffinity.topologyKey | quote }}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
Create the name for the auth secret.
*/}}
{{- define "rediscl.authSecret" -}}
{{- if .Values.auth.existingSecret -}}
{{- .Values.auth.existingSecret -}}
{{- else -}}
{{- include "rediscl.fullname" . -}}
{{- end -}}
{{- end -}}

{{/*
Get the bus port.
*/}}
{{- define "rediscl.busPort" -}}
{{- add 10000 (int .Values.redis.port) -}}
{{- end -}}

{{/*
Get the announce address.
*/}}
{{- define "rediscl.announce" -}}
{{- $groups := int .Values.groups -}}
{{- $dbport := int .Values.redis.port -}}
{{- range $i := until $groups -}}
{{- with $ -}}
{{- if gt $i 0 -}},{{- end -}}
{{- include "rediscl.fullname" . -}}-announce-{{ $i }}-0.{{ .Release.Namespace }}.svc:{{ $dbport }}
{{- end -}}
{{- end -}}
{{- end -}}
