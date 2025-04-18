-- Toggle convar
local pp_anaglyph_3d = CreateClientConVar("pp_anaglyph_3d", "0", false, false)

-- Create RTs & materials
local leftRT  = GetRenderTarget(
	"AnaglyphLeftRT",  
	ScrW(), ScrH())

local rightRT = GetRenderTarget(
	"AnaglyphRightRT",  
	ScrW(), ScrH())

    local matLeft = CreateMaterial("AnaglyphLeftRed", "UnlitGeneric", {
    ["$basetexture"]     = leftRT:GetName(),
    ["$translucent"]     = "1",
    ["$color"]           = "[.75 0 0]" -- Only store red and because we are blending two textures it gets too bright, so we need to scale it down a bit
})

-- Blue‑only version of right RT
local matRight = CreateMaterial("AnaglyphRightBlue", "UnlitGeneric", {
    ["$basetexture"]     = rightRT:GetName(),
    ["$translucent"]     = "1",
    ["$color"]           = "[0 .75 .75]" -- Only store green and blue (cyan) and because we are blending two textures it gets too bright, so we need to scale it down a bit
})

local eyeSeparationmm = 63 -- millimeters (63 is average for adults and in the range of 50-75)
local eyeSeparation = eyeSeparationmm / 19.03

hook.Add("RenderScene", "Anaglyph3D_Capture", function(origin, angles, fov)
    if not pp_anaglyph_3d:GetBool() then return end

    -- Prepare view data
    local view = { x=0, y=0, w=ScrW(), h=ScrH(), fov=fov, angles=angles }
	view.drawmonitors = true 
    view.drawhud = true 
    view.dopostprocess = true
    
	-- render.Clear(255, 255, 0, 255) -- Clear the screen to black

    -- Left eye (red)
    view.origin = origin - angles:Right() * (eyeSeparation * 0.5)
    render.PushRenderTarget(leftRT)
    -- render.Clear(0, 0, 0, 255)

    render.RenderView(view)
    render.PopRenderTarget()

    -- Right eye (blue)

    view.origin = origin + angles:Right() * (eyeSeparation * 0.5)
    render.PushRenderTarget(rightRT)
    -- render.Clear(0, 0, 0, 255)
    render.RenderView(view)
    render.PopRenderTarget()


    return true  -- fully override default scene 
end)


hook.Add("HUDPaint", "Anaglyph3D_Composite", function()
    if not pp_anaglyph_3d:GetBool() then return end

    render.OverrideBlend(true, BLEND_ONE, BLEND_ONE, BLENDFUNC_ADD)

    surface.SetDrawColor(255,255,255,255)   -- full brightness, material handles channel mask
    -- surface.DrawRect(0,0,ScrW(),ScrH()) -- clear the screen to white
    surface.SetMaterial(matLeft)
    surface.DrawTexturedRect(0,0,ScrW(),ScrH())
    surface.SetMaterial(matRight)
    surface.DrawTexturedRect(0,0,ScrW(),ScrH())


    render.OverrideBlend(false)

    
end)


list.Set( "PostProcess", "Anaglyph 3D", {
	icon		= "materials/gui/Blues_Brothers.jpg",
	convar = "pp_anaglyph_3d",
	category = "GuuscoNL's Post Process",
})

print("GUUSCONL POST PROCESS UPADTED")
