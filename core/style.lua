local style = {}

style.main = renderer.font.load(EXEDIR .. "/data/fonts/font.ttf", 14 * SCALE)
style.big_font = renderer.font.load(EXEDIR .. "/data/fonts/font.ttf", 34 * SCALE)
style.code_font = renderer.font.load(EXEDIR .. "/data/fonts/monospace.ttf", 13.5 * SCALE)
style.monospace = renderer.font.load(EXEDIR .. "/data/fonts/DejaVuSansMono.ttf", 18.5 * SCALE)

style.background = { 25, 25, 25, 255 }

return style
