module("luci.controller.yaffmap", package.seeall)


function index()
	entry({"admin", "freifunk", "yaffmap"}, cbi("yaffmap-properties"), "Yaffmap Node Einstellungen", 100)
	assign({"mini", "freifunk", "yaffmap"}, {"admin", "freifunk", "yaffmap"}, "Bulletin Node Einstellungen", 50)
end

