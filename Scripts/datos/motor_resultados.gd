class_name MotorResultados
extends RefCounted

## Réplica en GDScript de la hoja DIAGNÓSTICO/PROGRAMAS del Excel:
##   Total = 0.4 * área + 0.4 * fortalezas + 0.2 * objetivo
##   área: 1 si el área elegida está entre las del programa
##   fortalezas: 0.5 por cada fortaleza elegida que el programa tenga
##   objetivo: 1 si el objetivo elegido está entre los del programa
## Desempate (igual que el Excel): a igual porcentaje gana la fila más abajo.

const RUTA_JSON := "res://data/programas.json"
const PESO_AREA := 0.4
const PESO_FORTALEZAS := 0.4
const PESO_OBJETIVO := 0.2

static var _cache: Dictionary = {}


static func calcular_top(area: String, fortaleza_1: String, fortaleza_2: String, objetivo: String, cantidad: int = 3) -> Array:
	var resultados: Array = []

	for programa in _cargar().get("programas", []):
		var puntaje_area := 1.0 if area in programa["areas"] else 0.0

		var puntaje_fortalezas := 0.0
		if fortaleza_1 in programa["fortalezas"]:
			puntaje_fortalezas += 0.5
		if fortaleza_2 in programa["fortalezas"]:
			puntaje_fortalezas += 0.5

		var puntaje_objetivo := 1.0 if objetivo in programa["objetivos"] else 0.0

		var total := puntaje_area * PESO_AREA + puntaje_fortalezas * PESO_FORTALEZAS + puntaje_objetivo * PESO_OBJETIVO

		resultados.append({
			"nombre": programa["nombre"],
			"nivel": programa["nivel"],
			"facultad": programa["facultad"],
			"modalidad": programa["modalidad"],
			"descripcion": programa["descripcion"],
			"afinidad": roundi(total * 100.0),
			"desempate": programa["desempate"],
		})

	resultados.sort_custom(_ordenar)
	return resultados.slice(0, cantidad)


static func _ordenar(a: Dictionary, b: Dictionary) -> bool:
	if a["afinidad"] != b["afinidad"]:
		return a["afinidad"] > b["afinidad"]
	return a["desempate"] > b["desempate"]


static func _cargar() -> Dictionary:
	if not _cache.is_empty():
		return _cache
	var archivo := FileAccess.open(RUTA_JSON, FileAccess.READ)
	if archivo == null:
		push_error("No se pudo abrir " + RUTA_JSON + ". ¿Está en la carpeta data?")
		return {}
	var datos = JSON.parse_string(archivo.get_as_text())
	if datos is Dictionary:
		_cache = datos
	return _cache
