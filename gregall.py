import fontforge
ifnt=fontforge.open("gregall.sfd")
ifnt.selection.none()
start = 0xe400
m = open("mapping", "r")
last = ''
lastnewname = ''
for line in m:
  pos = line.find('\t')
  if line[pos+1:-1] == last:
    print "['" + line[0:pos] + "'] = '" + lastnewname + "'"
    continue
  last=line[pos+1:-1]
  lastnewname = line[0:pos]
  newname = lastnewname.replace("-","N").replace(">","B").replace("!","E").replace("~","T")
  try:
    ifnt.selection.select(("singletons",), last)
  except:
    start = start + 1
    continue
  ifnt.cut()
  ifnt.selection.select(("singletons",), "u%05x" % start)
  ifnt.paste()
  ifnt[start].glyphname = newname
  start = start + 1
ifnt.save("gregallnew.sfd")
