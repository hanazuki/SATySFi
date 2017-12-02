open HorzBox

exception InvalidFontAbbrev of font_abbrev

val initialize : string -> unit

val get_metrics_of_word : horz_string_info -> Uchar.t list -> OutputText.t * length * length * length

val get_math_char_info : math_string_info -> int -> Uchar.t -> FontFormat.glyph_id * length * length * length * length * FontFormat.math_kern_info option

val get_tag_and_encoding : font_abbrev -> string * encoding_in_pdf

val get_math_string_info : int -> math_context -> math_string_info

val get_math_tag : math_font_abbrev -> string

type math_kern_scheme

val no_math_kern : math_kern_scheme

val make_discrete_math_kern : FontFormat.math_kern -> math_kern_scheme

val make_dense_math_kern : (length -> length) -> math_kern_scheme

val get_math_kern : math_context -> int -> math_kern_scheme -> length -> length

val get_math_constants : math_context -> FontFormat.math_constants

val get_font_dictionary : Pdf.t -> Pdf.pdfobject
