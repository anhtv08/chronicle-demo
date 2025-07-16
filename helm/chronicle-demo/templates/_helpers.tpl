{{/*
Expand the name of the chart.
*/}}
{{- define "chronicle-demo.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "chronicle-demo.fullname" -}}
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
{{- define "chronicle-demo.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "chronicle-demo.labels" -}}
helm.sh/chart: {{ include "chronicle-demo.chart" . }}
{{ include "chronicle-demo.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- with .Values.labels }}
{{ toYaml . }}
{{- end }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "chronicle-demo.selectorLabels" -}}
app.kubernetes.io/name: {{ include "chronicle-demo.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "chronicle-demo.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "chronicle-demo.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Create the image name
*/}}
{{- define "chronicle-demo.image" -}}
{{- if .Values.global.imageRegistry }}
{{- printf "%s/%s:%s" .Values.global.imageRegistry .Values.image.repository (.Values.image.tag | default .Chart.AppVersion) }}
{{- else if .Values.image.registry }}
{{- printf "%s/%s:%s" .Values.image.registry .Values.image.repository (.Values.image.tag | default .Chart.AppVersion) }}
{{- else }}
{{- printf "%s:%s" .Values.image.repository (.Values.image.tag | default .Chart.AppVersion) }}
{{- end }}
{{- end }}

{{/*
Create the name of the config map
*/}}
{{- define "chronicle-demo.configMapName" -}}
{{- printf "%s-config" (include "chronicle-demo.fullname" .) }}
{{- end }}

{{/*
Create the name of the secret
*/}}
{{- define "chronicle-demo.secretName" -}}
{{- printf "%s-secret" (include "chronicle-demo.fullname" .) }}
{{- end }}

{{/*
Create the name of the PVC
*/}}
{{- define "chronicle-demo.pvcName" -}}
{{- printf "%s-pvc" (include "chronicle-demo.fullname" .) }}
{{- end }}

{{/*
Create the name of the route
*/}}
{{- define "chronicle-demo.routeName" -}}
{{- printf "%s-route" (include "chronicle-demo.fullname" .) }}
{{- end }}

{{/*
Create the name of the SCC
*/}}
{{- define "chronicle-demo.sccName" -}}
{{- default (printf "%s-scc" (include "chronicle-demo.fullname" .)) .Values.openshift.scc.name }}
{{- end }}

{{/*
Return the proper Storage Class
*/}}
{{- define "chronicle-demo.storageClass" -}}
{{- if .Values.global.storageClass }}
{{- .Values.global.storageClass }}
{{- else if .Values.persistence.storageClass }}
{{- .Values.persistence.storageClass }}
{{- end }}
{{- end }}

{{/*
Return the proper image pull secrets
*/}}
{{- define "chronicle-demo.imagePullSecrets" -}}
{{- $pullSecrets := list }}
{{- if .Values.global.imagePullSecrets }}
{{- $pullSecrets = .Values.global.imagePullSecrets }}
{{- end }}
{{- if .Values.image.pullSecrets }}
{{- $pullSecrets = concat $pullSecrets .Values.image.pullSecrets }}
{{- end }}
{{- if (not (empty $pullSecrets)) }}
imagePullSecrets:
{{- range $pullSecrets }}
  - name: {{ . }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Validate values
*/}}
{{- define "chronicle-demo.validateValues" -}}
{{- if and .Values.persistence.enabled (not .Values.persistence.size) }}
chronicle-demo: persistence.size
    You must provide a size for the persistent volume when persistence is enabled
{{- end }}
{{- if and .Values.autoscaling.enabled (not .Values.autoscaling.targetCPUUtilizationPercentage) (not .Values.autoscaling.targetMemoryUtilizationPercentage) }}
chronicle-demo: autoscaling
    You must provide either targetCPUUtilizationPercentage or targetMemoryUtilizationPercentage when autoscaling is enabled
{{- end }}
{{- end }}