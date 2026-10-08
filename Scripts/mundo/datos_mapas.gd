class_name DatosMapas
extends RefCounted
## Datos de cada mapa con arte propio. La clave es el nombre del archivo de la ficha
## (sin ".tres"). Las coordenadas son del mundo de 640x360.
##   edificio:   punto de referencia de la puerta (la zona de entrada queda 20 px debajo)
##   inicio:     dónde aparece el jugador al llegar al mapa
##   regreso:    dónde aparece al salir del edificio
##   huella:     polígono que bloquea el paso donde está dibujado el edificio
##   obstaculos: rectángulos que bloquean setos, bancas, árboles, etc.

const MAPAS := {
	"tecnologia_y_computacion": {
		"imagen": "res://assets/mapas/tecnologia_y_computacion.png",
		"edificio": Vector2(330, 215),
		"inicio": Vector2(320, 323),
		"regreso": Vector2(322, 285),
		"huella": [
			Vector2(261, 56), Vector2(330, 21), Vector2(511, 76),
			Vector2(511, 199), Vector2(430, 263), Vector2(262, 194),
		],
		"obstaculos": [
			Rect2(0, 0, 640, 34),      # árboles del borde superior
			Rect2(0, 34, 58, 250),     # árboles y seto del borde izquierdo
			Rect2(586, 34, 54, 326),   # árboles y seto del borde derecho
			Rect2(0, 306, 64, 54),     # arbusto esquina inferior izquierda
			Rect2(36, 34, 181, 26),    # seto superior izquierdo
			Rect2(480, 34, 128, 26),   # seto superior derecho
			Rect2(62, 169, 36, 57),    # máquina de carga
			Rect2(44, 228, 29, 45),    # banca izquierda abajo
			Rect2(57, 92, 16, 47),     # banca izquierda arriba
			Rect2(114, 63, 47, 24),    # banca superior
			Rect2(167, 65, 16, 22),    # basurero superior
			Rect2(62, 65, 44, 27),     # flores superior izquierda
			Rect2(541, 65, 44, 27),    # flores superior derecha
			Rect2(575, 92, 15, 47),    # banca derecha
			Rect2(133, 324, 69, 33),   # banca inferior izquierda
			Rect2(212, 328, 23, 29),   # basurero inferior izquierdo
			Rect2(406, 328, 21, 29),   # basurero inferior derecho
			Rect2(440, 324, 68, 33),   # banca inferior derecha
			Rect2(52, 326, 57, 26),    # flores inferior izquierda
			Rect2(541, 324, 68, 28),   # flores inferior derecha
		],
	},
}
