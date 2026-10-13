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


## Definiciones de cada opción (hoja GLOSARIO de la matriz). Se muestran como
## leyenda cuando el jugador enfoca una opción.
const DEFINICIONES := {
	"Razonamiento matemático": "Facilidad para comprender relaciones numéricas, utilizar conceptos matemáticos y abordar situaciones mediante razonamiento cuantitativo.",
	"Pensamiento lógico": "Capacidad para organizar ideas, identificar relaciones y llegar a conclusiones coherentes mediante razonamiento estructurado.",
	"Creatividad e imaginación": "Capacidad para generar ideas originales, visualizar alternativas y proponer formas diferentes de abordar una situación.",
	"Comunicación": "Capacidad para expresar ideas con claridad, escuchar, argumentar y transmitir información de manera efectiva.",
	"Curiosidad e investigación": "Interés por formular preguntas, explorar, buscar evidencia y comprender con mayor profundidad cómo y por qué ocurren las cosas.",
	"Afinidad con la tecnología": "Facilidad e interés por comprender, utilizar y explorar herramientas, dispositivos y soluciones tecnológicas.",
	"Liderazgo e iniciativa": "Disposición para proponer, tomar la iniciativa, movilizar a otras personas y asumir responsabilidades para alcanzar objetivos.",
	"Resolución de problemas": "Capacidad para identificar dificultades, analizar alternativas y plantear soluciones viables ante situaciones complejas.",
	"Habilidad práctica": "Facilidad para aprender haciendo, manipular herramientas o materiales y desarrollar actividades técnicas o aplicadas.",
	"Análisis e interpretación de información": "Capacidad para examinar datos o información, identificar patrones, relacionar variables y obtener conclusiones útiles.",
	"Organización y gestión": "Capacidad para planear actividades, ordenar recursos, hacer seguimiento y coordinar acciones para alcanzar resultados.",
	"Sensibilidad ambiental": "Interés y conciencia frente al cuidado del ambiente, los recursos naturales y los efectos de las actividades humanas sobre el entorno.",
	"Trabajo con personas y empatía": "Facilidad para relacionarse, comprender necesidades y perspectivas de otras personas y trabajar de manera cercana con ellas.",
	"Atención al detalle y precisión": "Capacidad para trabajar cuidadosamente, identificar pequeñas diferencias y mantener exactitud en procedimientos, mediciones o resultados.",
	"Crear y desarrollar tecnología": "Orientarse a crear, adaptar o desarrollar sistemas, herramientas y soluciones tecnológicas.",
	"Investigar y generar conocimiento": "Profundizar en preguntas y problemas para producir nuevos conocimientos mediante investigación y análisis riguroso.",
	"Diseñar, construir o mejorar soluciones": "Aplicar conocimientos para concebir, implementar u optimizar productos, sistemas, procesos o soluciones concretas.",
	"Dirigir empresas, equipos o proyectos": "Asumir responsabilidades de liderazgo, coordinación y toma de decisiones en organizaciones, equipos o proyectos.",
	"Crear mi propio negocio o emprender": "Convertir ideas u oportunidades en iniciativas, empresas o proyectos propios y gestionar su desarrollo.",
	"Trabajar por el medio ambiente y la sostenibilidad": "Contribuir profesionalmente a la protección ambiental, el uso responsable de recursos y el desarrollo sostenible.",
	"Enseñar y formar a otras personas": "Desarrollarse profesionalmente acompañando procesos educativos, de aprendizaje y formación.",
	"Trabajar en industria, producción y procesos": "Desarrollarse en entornos productivos, industriales u operativos, participando en su gestión, ejecución o mejoramiento.",
	"Contribuir al desarrollo del campo y los territorios": "Aportar al desarrollo rural y territorial mediante actividades productivas, ambientales, agrícolas o forestales.",
	"Trabajar con personas y contribuir a la sociedad": "Desarrollar una profesión con interacción humana y orientación al bienestar, servicio o transformación social.",
	"Desarrollarme en turismo, cultura y servicios": "Construir una trayectoria profesional vinculada con turismo, patrimonio, cultura, hospitalidad y gestión de servicios.",
	# Estas dos no están en el glosario: redactadas aquí, conviene validarlas con la oficina.
	"Crear, interpretar o desarrollar expresiones artísticas y culturales": "Dedicarse a crear, interpretar o producir obras y expresiones artísticas y culturales.",
	"Cuidar la salud y mejorar el bienestar": "Contribuir profesionalmente al cuidado de la salud y al bienestar físico y emocional de las personas.",
	"Analizar información y resolver problemas complejos": "Utilizar pensamiento analítico, modelos, datos y métodos rigurosos para comprender situaciones y apoyar soluciones o decisiones.",
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


## Definición de una opción (vacía si no la tiene).
static func definicion_de(valor: String) -> String:
	return DEFINICIONES.get(valor, "")


## Nombres de las opciones de una categoría, en una sola línea.
static func resumen_categoria(tipo: int, categoria: String) -> String:
	var opciones: Array = categorias_para(tipo).get(categoria, [])
	return " · ".join(PackedStringArray(opciones))
