class_name ReadableUI
extends Control

@onready var readable_title: Label = %ReadableTitle
@onready var readable_content: RichTextLabel = %ReadableContent


func set_content(title: String, content: String, rich_text: bool) -> void:
	readable_title.text = tr(title)
	if rich_text:
		readable_content.bbcode_enabled = true
		readable_content.bbcode_text = tr(content)
	else:
		readable_content.text = tr(content)
