extends Node

class_name RandomGen

const characters = 'abcdefghijklmnopqrstuvwxyz'

static func generate_word(chars=characters, length=10):
	var word: String
	var n_char = len(chars)
	for i in range(length):
		word += chars[randi()% n_char]
	return word
