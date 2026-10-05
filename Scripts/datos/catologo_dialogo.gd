class_name CatalogoDialogo
extends RefCounted

## Categorías visuales -> opciones EXACTAS de la matriz.
## Si la matriz cambia, se edita solo este archivo.

const FORTALEZAS := {
	"Lógica y análisis": [
		"Razonamiento matemático",
		"Pensamiento lógico",
		"Análisis e interpretación de información",
	],
	"Creatividad y expresión": [
		"Creatividad e imaginación",
		"Comunicación",
	],
	"Personas y liderazgo": [
		"Liderazgo e iniciativa",
		"Trabajo con personas y empatía",
	],
	"Técnica y precisión": [
		"Afinidad con la tecnología",
		"Habilidad práctica",
		"Atención al detalle y precisión",
	],
	"Curiosidad y gestión": [
		"Curiosidad e investigación",
		"Resolución de problemas",
		"Organización y gestión",
		"Sensibilidad ambiental",
	],
}

const OBJETIVOS := {
	"Crear y construir": [
		"Crear y desarrollar tecnología",
		"Diseñar, construir o mejorar soluciones",
		"Crear, interpretar o desarrollar expresiones artísticas y culturales",
	],
	"Investigar y analizar": [
		"Investigar y generar conocimiento",
		"Analizar información y resolver problemas complejos",
	],
	"Liderar y emprender": [
		"Dirigir empresas, equipos o proyectos",
		"Crear mi propio negocio o emprender",
		"Desarrollarme en turismo, cultura y servicios",
	],
	"Formar y cuidar personas": [
		"Enseñar y formar a otras personas",
		"Trabajar con personas y contribuir a la sociedad",
		"Cuidar la salud y mejorar el bienestar",
	],
	"Producir y desarrollar territorio": [
		"Trabajar en industria, producción y procesos",
		"Contribuir al desarrollo del campo y los territorios",
		"Trabajar por el medio ambiente y la sostenibilidad",
	],
}


static func categorias_para(tipo: int) -> Dictionary:
	if tipo == Npc.Tipo.OBJETIVO:
		return OBJETIVOS
	return FORTALEZAS


static func titulo_para(tipo: int) -> String:
	match tipo:
		Npc.Tipo.FORTALEZA_1:
			return "Tu primera fortaleza"
		Npc.Tipo.FORTALEZA_2:
			return "Tu segunda fortaleza"
	return "Tu objetivo profesional"


static func pregunta_para(tipo: int) -> String:
	if tipo == Npc.Tipo.OBJETIVO:
		return "¿Qué quieres lograr?"
	return "¿Qué se te da mejor?"
