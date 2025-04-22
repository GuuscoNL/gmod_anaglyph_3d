-- Toggle convar
local pp_anaglyph_3d = CreateClientConVar("pp_anaglyph_3d", "0", false, false)

-- Create RTs & materials
local leftRT  = GetRenderTarget(
	"AnaglyphLeftRT",  
	ScrW(), ScrH())

local rightRT = GetRenderTarget(
	"AnaglyphRightRT",  
	ScrW(), ScrH())

-- local leftVMRT  = GetRenderTarget(
--     "AnaglyphLeftVMT",  
--     ScrW(), ScrH())

-- local rightVMRT = GetRenderTarget(
--     "AnaglyphRightVMT",  
--     ScrW(), ScrH())

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

-- local matLeftVM = CreateMaterial("AnaglyphLeftRedVM", "UnlitGeneric", {
--     ["$basetexture"]     = leftVMRT:GetName(),
--     ["$translucent"]     = "1",
--     -- ["$vertexalpha"] = "1",
--     -- ["$vertexcolor"] = "1"
--     ["$color"]           = "[1 0 0]" -- Only store red and because we are blending two textures it gets too bright, so we need to scale it down a bit
-- })

-- local matRightVM = CreateMaterial("AnaglyphRightBlueVM", "UnlitGeneric", {
--     ["$basetexture"]     = rightVMRT:GetName(),
--     ["$translucent"]     = "1",
--     -- ["$vertexalpha"] = "1",
--     -- ["$vertexcolor"] = "1"
--     ["$color"]           = "[0 1 1]" -- Only store green and blue (cyan) and because we are blending two textures it gets too bright, so we need to scale it down a bit
-- })

local eyeSeparationmm = 63 -- millimeters (63 is average for adults and in the range of 50-75)
local eyeSeparation = eyeSeparationmm / 19.03

local eyeSeparationVMmm = 15 -- millimeters (63 is average for adults and in the range of 50-75)
local eyeSeparationVM = eyeSeparationVMmm / 19.03

-- #TODO: Am I going to use this? Was an idea to render the viewmodel separately, but didn't work as expected...
-- local function render3DViewModel(origin, angles)
--     vmOriginLeft = origin - angles:Right() * (eyeSeparationVM * 0.5)
--     render.PushRenderTarget(leftVMRT)
--     render.Clear(0, 0, 0, 0, true, true)
    

--     cam.Start3D(vmOriginLeft, angles, 70)
--         local vm = LocalPlayer():GetViewModel()
--         if IsValid(vm) then
    
--             vm:DrawModel()
            
--         end
--     cam.End3D()
    
--     render.PopRenderTarget()

--     vmOriginRight = origin + angles:Right() * (eyeSeparationVM * 0.5)

--     render.PushRenderTarget(rightVMRT)
--     render.Clear(0, 0, 0, 0, true, true)

--     cam.Start3D(vmOriginRight, angles, 70)
--         local vm = LocalPlayer():GetViewModel()
--         if IsValid(vm) then
    
    
--             vm:DrawModel()
            
--         end
--     cam.End3D()

--     render.PopRenderTarget()
-- end

hook.Add("RenderScene", "Anaglyph3D_Capture", function(origin, angles, fov)
    if not pp_anaglyph_3d:GetBool() then return end
    

    -- Prepare view data
    local view = { x=0, y=0, w=ScrW(), h=ScrH(), fov=fov, angles=angles }
	view.drawmonitors = true 
    view.drawhud = true 
    view.dopostprocess = true
    view.drawviewmodel = true
    view.viewmodelfov = fov
    
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


    -- render3DViewModel(origin, angles)
    
    return true  -- fully override default scene 
end)


hook.Add("HUDPaint", "Anaglyph3D_Composite", function()
    if not pp_anaglyph_3d:GetBool() then return end

    render.OverrideBlend(true, BLEND_ONE, BLEND_ONE, BLENDFUNC_ADD)

    surface.SetDrawColor(255,255,255,255)   -- full brightness, material handles channel mask

    surface.SetMaterial(matLeft)
    surface.DrawTexturedRect(0,0,ScrW(),ScrH())
    
    surface.SetMaterial(matRight)
    surface.DrawTexturedRect(0,0,ScrW(),ScrH())

    -- make sure the viewmodel is drawn on top of the anaglyph
    -- and not the other way around
    -- render.OverrideBlend(true, BLEND_ONE, BLEND_ONE, BLENDFUNC_ADD)
    -- matLeftVM:SetVector("$color", Vector(10, 0, 0))
    -- matRightVM:SetVector("$color", Vector(0, 10, 10))

    -- surface.SetMaterial(matLeftVM)
    -- surface.DrawTexturedRect(0,0,ScrW(),ScrH())
    
    -- surface.SetMaterial(matRightVM)
    -- surface.DrawTexturedRect(0,0,ScrW(),ScrH())
    render.OverrideBlend(false)

    
end)


list.Set( "PostProcess", "Anaglyph 3D", {
	icon		= "materials/gui/Blues_Brothers.jpg",
	convar = "pp_anaglyph_3d",
	category = "GuuscoNL's Post Process",
})

print("GUUSCONL POST PROCESS UPADTED")
