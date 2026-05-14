extends Node

signal warmup_completed

const META_PENDING_URL := "_cdn_pending_texture_url"

var _texture_cache: Dictionary = {}
var _pending_targets: Dictionary = {}
var _warmup_urls: Dictionary = {}
var _warmup_total: int = 0
var _warmup_loaded: int = 0


func warm_cache(remote_urls: Array[String]) -> void:
	_warmup_urls.clear()
	_warmup_loaded = 0
	var urls_to_fetch: Array[String] = []
	for url: String in remote_urls:
		if url == "":
			continue
		if _texture_cache.has(url):
			continue
		if not _warmup_urls.has(url):
			_warmup_urls[url] = true
			urls_to_fetch.append(url)
	_warmup_total = urls_to_fetch.size()
	if _warmup_total == 0:
		warmup_completed.emit()
		return
	for url: String in urls_to_fetch:
		if _pending_targets.has(url):
			continue
		_pending_targets[url] = []
		var request: HTTPRequest = HTTPRequest.new()
		add_child(request)
		request.request_completed.connect(_on_request_completed.bind(url, request))
		var request_error: int = request.request(url)
		if request_error != OK:
			request.queue_free()
			_pending_targets.erase(url)
			_on_warmup_url_done()


func get_warmup_progress() -> float:
	if _warmup_total <= 0:
		return 1.0
	return float(_warmup_loaded) / float(_warmup_total)


func _on_warmup_url_done() -> void:
	_warmup_loaded += 1
	if _warmup_loaded >= _warmup_total:
		warmup_completed.emit()


func apply_texture(texture_rect: TextureRect, remote_url: String, fallback_texture: Texture2D) -> void:
	if texture_rect == null:
		return

	texture_rect.texture = fallback_texture
	texture_rect.set_meta(META_PENDING_URL, remote_url)

	if remote_url == "":
		return

	var cached_variant: Variant = _texture_cache.get(remote_url, null)
	if cached_variant is Texture2D:
		texture_rect.texture = cached_variant
		texture_rect.visible = true
		return

	var pending_variants: Array = _pending_targets.get(remote_url, [])
	pending_variants.append(weakref(texture_rect))
	_pending_targets[remote_url] = pending_variants
	if pending_variants.size() > 1:
		return

	var request: HTTPRequest = HTTPRequest.new()
	add_child(request)
	request.request_completed.connect(_on_request_completed.bind(remote_url, request))
	var request_error: int = request.request(remote_url)
	if request_error != OK:
		request.queue_free()
		_pending_targets.erase(remote_url)


func _on_request_completed(
	result: int,
	response_code: int,
	_headers: PackedStringArray,
	body: PackedByteArray,
	remote_url: String,
	request: HTTPRequest
) -> void:
	if request != null:
		request.queue_free()

	var texture: Texture2D = _decode_texture(remote_url, result, response_code, body)
	if texture != null:
		_texture_cache[remote_url] = texture

	var pending_variants: Array = _pending_targets.get(remote_url, [])
	_pending_targets.erase(remote_url)
	for pending_variant: Variant in pending_variants:
		if not (pending_variant is WeakRef):
			continue
		var target_variant: Variant = pending_variant.get_ref()
		if not (target_variant is TextureRect):
			continue
		var texture_rect: TextureRect = target_variant as TextureRect
		if texture_rect == null or not is_instance_valid(texture_rect):
			continue
		if str(texture_rect.get_meta(META_PENDING_URL, "")) != remote_url:
			continue
		if texture != null:
			texture_rect.texture = texture
			texture_rect.visible = true

	if _warmup_urls.has(remote_url):
		_on_warmup_url_done()


func _decode_texture(remote_url: String, result: int, response_code: int, body: PackedByteArray) -> Texture2D:
	if result != HTTPRequest.RESULT_SUCCESS:
		return null
	if response_code < 200 or response_code >= 300:
		return null
	if body.is_empty():
		return null

	var extension: String = _get_extension(remote_url)
	var image: Image = Image.new()
	var load_result: int = ERR_FILE_UNRECOGNIZED
	match extension:
		"png":
			load_result = image.load_png_from_buffer(body)
		"jpg", "jpeg":
			load_result = image.load_jpg_from_buffer(body)
		"webp":
			load_result = image.load_webp_from_buffer(body)
		_:
			return null

	if load_result != OK:
		return null
	return ImageTexture.create_from_image(image)


func _get_extension(remote_url: String) -> String:
	var trimmed_url: String = remote_url.split("?", true, 1)[0]
	var path_parts: PackedStringArray = trimmed_url.rsplit(".", true, 1)
	if path_parts.size() < 2:
		return ""
	return str(path_parts[1]).to_lower()
