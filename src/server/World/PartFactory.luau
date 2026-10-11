--!strict

local PartFactory = {}

function PartFactory.part(props: {
	name: string?,
	size: Vector3,
	cframe: CFrame,
	color: Color3,
	material: Enum.Material?,
	transparency: number?,
	parent: Instance,
	shape: Enum.PartType?,
	canCollide: boolean?,
	light: Color3?,
	lightRange: number?,
}): Part
	local p = Instance.new("Part")
	p.Name = props.name or "Part"
	p.Anchored = true
	p.Size = props.size
	p.CFrame = props.cframe
	p.Color = props.color
	p.Material = props.material or Enum.Material.SmoothPlastic
	p.Transparency = props.transparency or 0
	p.CanCollide = if props.canCollide == nil then true else props.canCollide
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.CastShadow = true
	if props.shape then
		p.Shape = props.shape
	end
	p.Parent = props.parent
	if props.light then
		local l = Instance.new("PointLight")
		l.Color = props.light
		l.Brightness = 1.4
		l.Range = props.lightRange or 24
		l.Parent = p
	end
	return p
end

function PartFactory.spawnPad(parent: Instance, cf: CFrame, color: Color3, name: string): Part
	local pad = PartFactory.part({
		name = name,
		size = Vector3.new(8, 1, 8),
		cframe = cf,
		color = color,
		material = Enum.Material.Neon,
		parent = parent,
		light = color,
		lightRange = 16,
	})
	pad:SetAttribute("SpawnPad", true)
	return pad
end

return PartFactory
