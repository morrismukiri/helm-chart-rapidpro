{{/*
Expand the name of the chart.
*/}}
{{- define "rapidpro.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "rapidpro.fullname" -}}
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
{{- define "rapidpro.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "rapidpro.labels" -}}
helm.sh/chart: {{ include "rapidpro.chart" . }}
{{ include "rapidpro.selectorLabels" . }}
app.kubernetes.io/version: {{ .Values.rapidpro.image.tag | default .Chart.AppVersion | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Mailroom labels
*/}}
{{- define "mailroom.labels" -}}
helm.sh/chart: {{ include "rapidpro.chart" . }}
{{ include "mailroom.selectorLabels" . }}
app.kubernetes.io/version: {{ .Values.mailroom.image.tag | default .Chart.AppVersion | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Courier labels
*/}}
{{- define "courier.labels" -}}
helm.sh/chart: {{ include "rapidpro.chart" . }}
{{ include "courier.selectorLabels" . }}
app.kubernetes.io/version: {{ .Values.courier.image.tag | default .Chart.AppVersion | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Indexer labels
*/}}
{{- define "indexer.labels" -}}
helm.sh/chart: {{ include "rapidpro.chart" . }}
{{ include "indexer.selectorLabels" . }}
app.kubernetes.io/version: {{ .Values.indexer.image.tag | default .Chart.AppVersion | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Archiver labels
*/}}
{{- define "archiver.labels" -}}
{{- if .Values.archiver.enabled }}
helm.sh/chart: {{ include "rapidpro.chart" . }}
{{ include "archiver.selectorLabels" . }}
app.kubernetes.io/version: {{ .Values.archiver.image.tag | default .Chart.AppVersion | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}
{{- end }}

{{/*
RapidPro Selector labels
*/}}
{{- define "rapidpro.selectorLabels" -}}
app.kubernetes.io/name: {{ include "rapidpro.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Mailroom Selector labels
*/}}
{{- define "mailroom.selectorLabels" -}}
app.kubernetes.io/name: {{ include "rapidpro.name" . }}-mailroom
app.kubernetes.io/instance: {{ .Release.Name }}-mailroom
{{- end }}

{{/*
Courier Selector labels
*/}}
{{- define "courier.selectorLabels" -}}
app.kubernetes.io/name: {{ include "rapidpro.name" . }}-courier
app.kubernetes.io/instance: {{ .Release.Name }}-courier
{{- end }}

{{/*
{{- end }}

{{/*
indexer Selector labels
*/}}
{{- define "indexer.selectorLabels" -}}
app.kubernetes.io/name: {{ include "rapidpro.name" . }}-indexer
app.kubernetes.io/instance: {{ .Release.Name }}-indexer
{{- end }}

{{/*
Archiver Selector labels
*/}}
{{- define "archiver.selectorLabels" -}}
{{- if .Values.archiver.enabled }}
app.kubernetes.io/name: {{ include "rapidpro.name" . }}-archiver
app.kubernetes.io/instance: {{ .Release.Name }}-archiver
{{- end }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "rapidpro.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "rapidpro.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Create smtp url from values
*/}}
{{- define "rapidpro.smtpUrl" -}}
{{- printf "smtp://%s:%s@%s:%v" .Values.smtp.username .Values.smtp.password .Values.smtp.host .Values.smtp.port -}}
{{- end }}

{{/* Database URL. Bundled = hand-rolled PostGIS service; else external. */}}
{{- define "rapidpro.databaseUrl" -}}
{{- if .Values.postgresql.enabled -}}
{{- printf "postgres://%s:%s@%s-postgresql:%v/%s" .Values.postgresql.auth.username .Values.postgresql.auth.password (include "rapidpro.fullname" .) (.Values.postgresql.service.port | default 5432) .Values.postgresql.auth.database -}}
{{- else -}}
{{- .Values.externalPostgresqlUrl -}}
{{- end -}}
{{- end }}

{{/* Read-only Database URL. Empty unless an external replica is configured;
     the app settings fall back to the primary when this is empty. */}}
{{- define "rapidpro.databaseUrlReadonly" -}}
{{- .Values.externalPostgresqlReadonlyUrl | default "" -}}
{{- end }}

{{/* Broker/cache base service host (hand-rolled redis OR valkey). */}}
{{- define "rapidpro.brokerService" -}}
{{- printf "%s-broker" (include "rapidpro.fullname" .) -}}
{{- end }}

{{/* App/celery broker+cache URL (db 15). */}}
{{- define "rapidpro.redisUrl" -}}
{{- if .Values.redis.enabled -}}
{{- printf "redis://%s:%v/%v" (include "rapidpro.brokerService" .) (.Values.redis.service.port | default 6379) (.Values.broker.appDb | default 15) -}}
{{- else -}}
{{- .Values.externalRedisUrl -}}
{{- end -}}
{{- end }}

{{/* Mailroom broker URL (db 11 by convention). */}}
{{- define "rapidpro.mailroomRedisUrl" -}}
{{- if .Values.mailroom.redisUrl -}}
{{- .Values.mailroom.redisUrl -}}
{{- else if .Values.redis.enabled -}}
{{- printf "redis://%s:%v/%v" (include "rapidpro.brokerService" .) (.Values.redis.service.port | default 6379) (.Values.broker.mailroomDb | default 11) -}}
{{- else -}}
{{- .Values.externalRedisUrl -}}
{{- end -}}
{{- end }}

{{/* Courier broker URL (db 12 by convention). */}}
{{- define "rapidpro.courierRedisUrl" -}}
{{- if .Values.courier.redisUrl -}}
{{- .Values.courier.redisUrl -}}
{{- else if .Values.redis.enabled -}}
{{- printf "redis://%s:%v/%v" (include "rapidpro.brokerService" .) (.Values.redis.service.port | default 6379) (.Values.broker.courierDb | default 12) -}}
{{- else -}}
{{- .Values.externalRedisUrl -}}
{{- end -}}
{{- end }}

{{/* Elasticsearch URL. Bundled = hand-rolled single node; else external. */}}
{{- define "rapidpro.elasticsearchUrl" -}}
{{- if .Values.elasticsearch.enabled -}}
{{- printf "http://%s-elasticsearch:%v" (include "rapidpro.fullname" .) (.Values.elasticsearch.service.port | default 9200) -}}
{{- else -}}
{{- .Values.externalElasticsearchUrl -}}
{{- end -}}
{{- end }}

{{/* S3 endpoint for the Go services. Explicit awsS3Endpoint wins (MinIO); else
     a region-correct AWS endpoint so signing matches the bucket's region. The Go
     binaries otherwise default to https://s3.amazonaws.com, which 400s outside
     us-east-1 (AuthorizationHeaderMalformed). */}}
{{- define "rapidpro.s3Endpoint" -}}
{{- if .Values.awsS3Endpoint -}}
{{- .Values.awsS3Endpoint -}}
{{- else if .Values.awsS3RegionName -}}
{{- printf "https://s3.%s.amazonaws.com" .Values.awsS3RegionName -}}
{{- else -}}
{{- "https://s3.amazonaws.com" -}}
{{- end -}}
{{- end }}

{{/* Broker image (redis or valkey) for the hand-rolled dev/staging broker. */}}
{{- define "rapidpro.brokerImage" -}}
{{- if eq (.Values.broker.engine | default "redis") "valkey" -}}
{{- printf "%s:%s" (.Values.broker.valkeyRepository | default "valkey/valkey") (.Values.broker.valkeyTag | default "8.1-alpine") -}}
{{- else -}}
{{- printf "%s:%s" (.Values.broker.redisRepository | default "redis") (.Values.broker.redisTag | default "7.2-alpine") -}}
{{- end -}}
{{- end }}