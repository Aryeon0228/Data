/*
	Remove Collinear Vertices
	Removes unnecessary vertices that lie on a straight edge
*/

try(destroyDialog RemoveCollinearVerts) catch()

rollout RemoveCollinearVerts "Remove Collinear Vertices" width:300 height:150
(
	spinner spnThresh "Threshold:" range:[0.0001, 10.0, 0.001] type:#float scale:0.001 pos:[10,15] width:280
	label lblInfo "" pos:[10,50]
	button btnRun "Remove" pos:[10,80] width:280 height:35 enabled:false
	button btnSelect "Select Verts (Preview)" pos:[10,120] width:280 height:22 enabled:false

	fn getCollinearVerts obj thresh =
	(
		local toRemove = #{}
		local numVerts = polyop.getNumVerts obj
		for i = 1 to numVerts do
		(
			local edges = polyop.getEdgesUsingVert obj i
			if edges.numberSet == 2 then
			(
				local edgeList = #()
				for e in edges do append edgeList e
				local ev1 = polyop.getEdgeVerts obj edgeList[1]
				local ev2 = polyop.getEdgeVerts obj edgeList[2]
				local neighbors = #()
				for v in ev1 do if v != i then append neighbors v
				for v in ev2 do if v != i then append neighbors v
				if neighbors.count == 2 then
				(
					local p0 = polyop.getVert obj i
					local p1 = polyop.getVert obj neighbors[1]
					local p2 = polyop.getVert obj neighbors[2]
					local dir = normalize (p2 - p1)
					local dist = length ((p0 - p1) - dir * (dot (p0 - p1) dir))
					if dist < thresh then append toRemove i
				)
			)
		)
		toRemove
	)

	fn updateInfo =
	(
		if selection.count == 0 then
		(
			lblInfo.text = "No object selected."
			btnRun.enabled = false
			btnSelect.enabled = false
		)
		else if selection.count > 1 then
		(
			lblInfo.text = (selection.count as string + " objects selected.")
			btnRun.enabled = true
			btnSelect.enabled = false
		)
		else if not isKindOf $ Editable_Poly then
		(
			lblInfo.text = "Selected object is not an Editable Poly."
			btnRun.enabled = false
			btnSelect.enabled = false
		)
		else
		(
			lblInfo.text = ("Target: " + $.name + " (" + (polyop.getNumVerts $) as string + " verts)")
			btnRun.enabled = true
			btnSelect.enabled = true
		)
	)

	on RemoveCollinearVerts open do updateInfo()

	on btnSelect pressed do
	(
		if selection.count == 1 and isKindOf $ Editable_Poly do
		(
			local verts = getCollinearVerts $ spnThresh.value
			polyop.setVertSelection $ verts
			subObjectLevel = 1
			lblInfo.text = (verts.numberSet as string + " collinear verts found.")
		)
	)

	on btnRun pressed do
	(
		local objs = for obj in selection where isKindOf obj Editable_Poly collect obj
		if objs.count == 0 then
		(
			messageBox "No Editable Poly objects in selection." title:"Notice"
			return undefined
		)

		local totalRemoved = 0
		local thresh = spnThresh.value

		undo "Remove Collinear Verts" on
		(
			for obj in objs do
			(
				local verts = getCollinearVerts obj thresh
				if verts.numberSet > 0 do
				(
					totalRemoved += verts.numberSet
					polyop.setVertSelection obj verts
					obj.Remove()
				)
			)
		)

		lblInfo.text = ("Removed " + totalRemoved as string + " verts from " + objs.count as string + " object(s).")
		if objs.count == 1 and isKindOf $ Editable_Poly then
			lblInfo.text += (" (" + (polyop.getNumVerts $) as string + " remaining)")
	)
)

createDialog RemoveCollinearVerts
