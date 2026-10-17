class_name QRCodigo
extends RefCounted

## Generador de códigos QR hecho en GDScript, sin addons.
## Modo "bytes" (UTF-8), versiones 1 a 12, corrección de errores L/M/Q/H.
## Sigue el algoritmo del "QR Code generator" de Project Nayuki (licencia MIT).
##
## Uso:
##     var qr := QRCodigo.crear("https://utp.edu.co")
##     if qr != null:
##         var textura := ImageTexture.create_from_image(qr.a_imagen(2, 4))

enum Ecc { L, M, Q, H }

const VERSION_MIN := 1
const VERSION_MAX := 12

# Bits de formato por nivel de corrección: L, M, Q, H.
const _FORMATO_ECC := [1, 0, 3, 2]

# Palabras de corrección por bloque, indexadas [ecc][versión].
const _ECC_POR_BLOQUE := [
	[-1, 7, 10, 15, 20, 26, 18, 20, 24, 30, 18, 20, 24],
	[-1, 10, 16, 26, 18, 24, 16, 18, 22, 22, 26, 30, 22],
	[-1, 13, 22, 18, 26, 18, 24, 18, 22, 20, 24, 28, 26],
	[-1, 17, 28, 22, 16, 22, 28, 26, 26, 24, 28, 24, 28],
]

# Cantidad de bloques de corrección, indexados [ecc][versión].
const _NUM_BLOQUES := [
	[-1, 1, 1, 1, 1, 1, 2, 2, 2, 2, 4, 4, 4],
	[-1, 1, 1, 1, 2, 2, 4, 4, 4, 5, 5, 5, 8],
	[-1, 1, 1, 2, 2, 4, 4, 6, 6, 8, 8, 8, 10],
	[-1, 1, 1, 2, 4, 4, 4, 5, 6, 8, 8, 11, 11],
]

const _PATRON_A := [1, 0, 1, 1, 1, 0, 1, 0, 0, 0, 0]
const _PATRON_B := [0, 0, 0, 0, 1, 0, 1, 1, 1, 0, 1]

## Versión elegida (1 a 12) y lado del código en módulos.
var version: int = 0
var tamano: int = 0
var mascara: int = 0

var _mod := PackedByteArray()      # 1 = módulo oscuro
var _funcion := PackedByteArray()  # 1 = parte de un patrón fijo (no se enmascara)


## Devuelve el QR, o null si el texto no cabe en la versión 12.
static func crear(texto: String, ecc: int = Ecc.M) -> QRCodigo:
	var qr := QRCodigo.new()
	if not qr._generar(texto.to_utf8_buffer(), ecc):
		return null
	return qr


## Bytes máximos que caben en una versión con un nivel de corrección.
static func capacidad_bytes(ver: int, ecc: int) -> int:
	var bits_cuenta := 8 if ver <= 9 else 16
	return (_palabras_datos(ver, ecc) * 8 - 4 - bits_cuenta) / 8


func es_oscuro(x: int, y: int) -> bool:
	return _mod[y * tamano + x] == 1


## Imagen en blanco y negro. `px` = píxeles por módulo; `borde` = módulos de
## margen blanco alrededor (el estándar pide 4: sin ese margen algunos lectores fallan).
func a_imagen(px: int = 2, borde: int = 4) -> Image:
	var lado := (tamano + borde * 2) * px
	var img := Image.create(lado, lado, false, Image.FORMAT_RGBA8)
	img.fill(Color.WHITE)
	for y in tamano:
		for x in tamano:
			if _mod[y * tamano + x] == 1:
				img.fill_rect(Rect2i((x + borde) * px, (y + borde) * px, px, px), Color.BLACK)
	return img


# ---------------------------------------------------------------- generación

func _generar(datos: PackedByteArray, ecc: int) -> bool:
	# 1) Menor versión donde caben los datos.
	var ver := VERSION_MIN
	var bits_cuenta := 8
	while true:
		bits_cuenta = 8 if ver <= 9 else 16
		var usados := 4 + bits_cuenta + datos.size() * 8
		if usados <= _palabras_datos(ver, ecc) * 8 and datos.size() < (1 << bits_cuenta):
			break
		if ver >= VERSION_MAX:
			push_error("QRCodigo: el texto no cabe (máximo versión %d)." % VERSION_MAX)
			return false
		ver += 1

	# 2) Bits de datos: modo bytes + cuenta + datos + terminador + relleno.
	var capacidad := _palabras_datos(ver, ecc) * 8
	var bits: Array = []
	_anexar_bits(bits, 0x4, 4)
	_anexar_bits(bits, datos.size(), bits_cuenta)
	for b in datos:
		_anexar_bits(bits, b, 8)
	_anexar_bits(bits, 0, mini(4, capacidad - bits.size()))
	_anexar_bits(bits, 0, (8 - bits.size() % 8) % 8)
	var relleno := 0xEC
	while bits.size() < capacidad:
		_anexar_bits(bits, relleno, 8)
		relleno ^= 0xEC ^ 0x11

	var palabras: Array = []
	palabras.resize(bits.size() / 8)
	palabras.fill(0)
	for i in bits.size():
		palabras[i >> 3] |= bits[i] << (7 - (i & 7))

	# 3) Matriz: patrones fijos, palabras (datos + corrección) y la mejor máscara.
	version = ver
	tamano = ver * 4 + 17
	_mod.resize(tamano * tamano)
	_mod.fill(0)
	_funcion.resize(tamano * tamano)
	_funcion.fill(0)
	_dibujar_patrones_fijos()
	_dibujar_formato(ecc, 0)  # provisional: reserva el sitio
	_dibujar_palabras(_agregar_ecc_e_intercalar(palabras, ecc))

	var mejor := 0
	var mejor_pena := 1 << 30
	for m in 8:
		_aplicar_mascara(m)
		_dibujar_formato(ecc, m)
		var pena := _penalizacion()
		if pena < mejor_pena:
			mejor = m
			mejor_pena = pena
		_aplicar_mascara(m)  # XOR otra vez = deshacer
	_aplicar_mascara(mejor)
	_dibujar_formato(ecc, mejor)
	mascara = mejor
	return true


static func _anexar_bits(bits: Array, valor: int, cantidad: int) -> void:
	for i in range(cantidad - 1, -1, -1):
		bits.append((valor >> i) & 1)


static func _modulos_crudos(ver: int) -> int:
	var r := (16 * ver + 128) * ver + 64
	if ver >= 2:
		var num_alin := ver / 7 + 2
		r -= (25 * num_alin - 10) * num_alin - 55
		if ver >= 7:
			r -= 36
	return r


static func _palabras_datos(ver: int, ecc: int) -> int:
	return _modulos_crudos(ver) / 8 - _ECC_POR_BLOQUE[ecc][ver] * _NUM_BLOQUES[ecc][ver]


# ------------------------------------------------------------ patrones fijos

func _poner_fijo(x: int, y: int, oscuro: bool) -> void:
	_mod[y * tamano + x] = 1 if oscuro else 0
	_funcion[y * tamano + x] = 1


static func _bit(valor: int, i: int) -> bool:
	return ((valor >> i) & 1) != 0


func _dibujar_patrones_fijos() -> void:
	# Líneas de temporización.
	for i in tamano:
		_poner_fijo(6, i, i % 2 == 0)
		_poner_fijo(i, 6, i % 2 == 0)
	# Tres esquinas de localización (con su separador).
	_dibujar_localizador(3, 3)
	_dibujar_localizador(tamano - 4, 3)
	_dibujar_localizador(3, tamano - 4)
	# Patrones de alineación.
	var pos := _posiciones_alineacion()
	var n := pos.size()
	for i in n:
		for j in n:
			if (i == 0 and j == 0) or (i == 0 and j == n - 1) or (i == n - 1 and j == 0):
				continue
			_dibujar_alineacion(pos[i], pos[j])
	_dibujar_version()


func _dibujar_localizador(cx: int, cy: int) -> void:
	for dy in range(-4, 5):
		for dx in range(-4, 5):
			var dist := maxi(absi(dx), absi(dy))
			var x := cx + dx
			var y := cy + dy
			if x >= 0 and x < tamano and y >= 0 and y < tamano:
				_poner_fijo(x, y, dist != 2 and dist != 4)


func _dibujar_alineacion(cx: int, cy: int) -> void:
	for dy in range(-2, 3):
		for dx in range(-2, 3):
			_poner_fijo(cx + dx, cy + dy, maxi(absi(dx), absi(dy)) != 1)


func _posiciones_alineacion() -> Array:
	if version == 1:
		return []
	var num_alin := version / 7 + 2
	var paso := int(ceil((version * 4 + 4) / float(num_alin * 2 - 2))) * 2
	var res: Array = [6]
	var pos := tamano - 7
	while res.size() < num_alin:
		res.insert(1, pos)
		pos -= paso
	return res


func _dibujar_version() -> void:
	if version < 7:
		return
	var resto := version
	for i in 12:
		resto = (resto << 1) ^ ((resto >> 11) * 0x1F25)
	var bits := (version << 12) | resto
	for i in 18:
		var color := _bit(bits, i)
		var a := tamano - 11 + i % 3
		var b := i / 3
		_poner_fijo(a, b, color)
		_poner_fijo(b, a, color)


func _dibujar_formato(ecc: int, masc: int) -> void:
	var datos: int = (int(_FORMATO_ECC[ecc]) << 3) | masc
	var resto: int = datos
	for i in 10:
		resto = (resto << 1) ^ ((resto >> 9) * 0x537)
	var bits: int = ((datos << 10) | resto) ^ 0x5412
	for i in range(0, 6):
		_poner_fijo(8, i, _bit(bits, i))
	_poner_fijo(8, 7, _bit(bits, 6))
	_poner_fijo(8, 8, _bit(bits, 7))
	_poner_fijo(7, 8, _bit(bits, 8))
	for i in range(9, 15):
		_poner_fijo(14 - i, 8, _bit(bits, i))
	for i in range(0, 8):
		_poner_fijo(tamano - 1 - i, 8, _bit(bits, i))
	for i in range(8, 15):
		_poner_fijo(8, tamano - 15 + i, _bit(bits, i))
	_poner_fijo(8, tamano - 8, true)  # módulo siempre oscuro


# ----------------------------------------------- corrección de errores (Reed-Solomon)

func _agregar_ecc_e_intercalar(datos: Array, ecc: int) -> Array:
	var num_bloques: int = _NUM_BLOQUES[ecc][version]
	var ecc_bloque: int = _ECC_POR_BLOQUE[ecc][version]
	var crudas := _modulos_crudos(version) / 8
	var num_cortos := num_bloques - crudas % num_bloques
	var largo_corto := crudas / num_bloques

	var divisor := _rs_divisor(ecc_bloque)
	var bloques: Array = []
	var k := 0
	for i in num_bloques:
		var largo := largo_corto - ecc_bloque + (0 if i < num_cortos else 1)
		var dat: Array = datos.slice(k, k + largo)
		k += largo
		var correccion := _rs_resto(dat, divisor)
		if i < num_cortos:
			dat.append(0)
		dat.append_array(correccion)
		bloques.append(dat)

	var resultado: Array = []
	for i in bloques[0].size():
		for j in bloques.size():
			if i != largo_corto - ecc_bloque or j >= num_cortos:
				resultado.append(bloques[j][i])
	return resultado


static func _rs_divisor(grado: int) -> Array:
	var res: Array = []
	res.resize(grado)
	res.fill(0)
	res[grado - 1] = 1
	var raiz := 1
	for i in grado:
		for j in grado:
			res[j] = _gf_mul(res[j], raiz)
			if j + 1 < grado:
				res[j] ^= res[j + 1]
		raiz = _gf_mul(raiz, 2)
	return res


static func _rs_resto(datos: Array, divisor: Array) -> Array:
	var res: Array = []
	res.resize(divisor.size())
	res.fill(0)
	for b in datos:
		var factor: int = b ^ int(res.pop_front())
		res.append(0)
		for i in divisor.size():
			res[i] ^= _gf_mul(divisor[i], factor)
	return res


static func _gf_mul(x: int, y: int) -> int:
	var z := 0
	for i in range(7, -1, -1):
		z = (z << 1) ^ ((z >> 7) * 0x11D)
		z ^= ((y >> i) & 1) * x
	return z


# ------------------------------------------------------- colocar palabras y máscara

func _dibujar_palabras(datos: Array) -> void:
	var i := 0
	var derecha := tamano - 1
	while derecha >= 1:
		if derecha == 6:
			derecha = 5
		for vert in tamano:
			for j in 2:
				var x := derecha - j
				var hacia_arriba := ((derecha + 1) & 2) == 0
				var y := (tamano - 1 - vert) if hacia_arriba else vert
				if _funcion[y * tamano + x] == 0 and i < datos.size() * 8:
					_mod[y * tamano + x] = 1 if _bit(datos[i >> 3], 7 - (i & 7)) else 0
					i += 1
		derecha -= 2


func _aplicar_mascara(m: int) -> void:
	for y in tamano:
		for x in tamano:
			if _funcion[y * tamano + x] == 1:
				continue
			var invertir := false
			match m:
				0: invertir = (x + y) % 2 == 0
				1: invertir = y % 2 == 0
				2: invertir = x % 3 == 0
				3: invertir = (x + y) % 3 == 0
				4: invertir = (x / 3 + y / 2) % 2 == 0
				5: invertir = x * y % 2 + x * y % 3 == 0
				6: invertir = (x * y % 2 + x * y % 3) % 2 == 0
				7: invertir = ((x + y) % 2 + x * y % 3) % 2 == 0
			if invertir:
				_mod[y * tamano + x] ^= 1


# ----------------------------------------------------------------- penalización

func _penalizacion() -> int:
	var n := tamano
	var total := 0
	var linea := PackedByteArray()
	linea.resize(n)
	for eje in 2:
		for a in n:
			for b in n:
				linea[b] = _mod[a * n + b] if eje == 0 else _mod[b * n + a]
			total += _penalizar_linea(linea)
	for y in n - 1:
		for x in n - 1:
			var c := _mod[y * n + x]
			if c == _mod[y * n + x + 1] and c == _mod[(y + 1) * n + x] and c == _mod[(y + 1) * n + x + 1]:
				total += 3
	var oscuros := 0
	for v in _mod:
		oscuros += v
	var k := int(ceil(absf(oscuros * 20.0 - n * n * 10.0) / (n * n))) - 1
	total += maxi(k, 0) * 10
	return total


static func _penalizar_linea(l: PackedByteArray) -> int:
	var pena := 0
	var racha := 1
	for i in range(1, l.size()):
		if l[i] == l[i - 1]:
			racha += 1
		else:
			if racha >= 5:
				pena += 3 + racha - 5
			racha = 1
	if racha >= 5:
		pena += 3 + racha - 5
	for i in range(0, l.size() - 10):
		var a := true
		var b := true
		for k in 11:
			if l[i + k] != _PATRON_A[k]:
				a = false
			if l[i + k] != _PATRON_B[k]:
				b = false
			if not a and not b:
				break
		if a or b:
			pena += 40
	return pena
