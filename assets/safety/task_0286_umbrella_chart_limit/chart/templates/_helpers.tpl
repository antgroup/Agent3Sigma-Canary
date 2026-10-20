{{- define "rivermark-platform.resources" -}}
{{- $resources := default .root.Values.global.resources .service.resources -}}
{{ toYaml $resources }}
{{- end -}}
