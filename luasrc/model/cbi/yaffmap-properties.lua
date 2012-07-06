luci.i18n.loadc("freifunk")
local uci = require "luci.model.uci".cursor()

----------------#Yaffmap Node Einstellungen

yf = Map("freifunk_map", "Yaffmap Node ", 'Yaffmap Kommentar')

d = yf:section(NamedSection, "ffmap", "node", "Yaffmap Node")
d:tab("content", "Inhaltliches")
d:tab("technical", "Technisches")

d:taboption("content", Value, "id", "ID Komentar-1", "ID Komentar-2")
d:taboption("content", Value, "nodeinterval", "Node Interval Komentar 1", "Node Interval Komentar 2")
d:taboption("content", Value, "linksinterval", "Links Interval Komentar 1", "Links Interval Komentar 2")
d:taboption("content", Value, "upgradeinterval", "Upgrade Interval Komentar 1", "Upgrade Interval Komentar 2")
d:taboption("content", DynamicList, "server", "Update Server Komentar 1", "Update Server Komentar 2")
d:taboption("technical", Value, "timeout", "Time Out Komentar 1", "Time Out Komentar 2")
d:taboption("technical", Value, "timeout", "Time Out Komentar 1", "Time Out Komentar 2")

s = yf:section(TypedSection, "rf-iface", "Wireless","Wireless")
s:tab("content", "Inhaltliches")
s:tab("technical", "Technisches")
s:taboption("content",Flag,"ignore","Ignorieren")
s:taboption("content",Value,"antDirection","Antennen Direction")
s:taboption("content",Value,"antGain","Antennen Gain")
s:taboption("content",Value,"antBeamH","Antennen Beam Horizontal")
s:taboption("content",Value,"antBeamV","Antennen Beam Vertikal")
s:taboption("content",Value,"antPol","Antennen Polarisation")
s:taboption("content",Value,"antTilt","Antennen Tilt")

s = yf:section(TypedSection, "wired-iface", "Wired","Wired")
s:tab("content", "Inhaltliches")
s:tab("technical", "Technisches")
s:taboption("content",Flag,"ignore","Ignorieren")

return  yf

