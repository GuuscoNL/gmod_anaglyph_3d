-- Toggle convar
local pp_anaglyph_3d = CreateClientConVar("pp_anaglyph_3d", "0", false, false)
local pp_anaglyph_3d_eye_separation = CreateClientConVar("pp_anaglyph_3d_eye_separation", "63", true, false, "millimeters (63 is average for adults and in the range of 50-75)", 0, 100)
local pp_anaglyph_3d_no_draw_viewmodel = CreateClientConVar("pp_anaglyph_3d_no_draw_viewmodel", "0", true, false)
-- local pp_anaglyph_3d_draw_hud = CreateClientConVar("pp_anaglyph_3d_draw_hud", "1", true, false)
local pp_anaglyph_3d_draw_monitors = CreateClientConVar("pp_anaglyph_3d_draw_monitors", "1", true, false)
local pp_anaglyph_3d_use_postprocess = CreateClientConVar("pp_anaglyph_3d_use_postprocess", "1", true, false)
local pp_anaglyph_3d_fov = CreateClientConVar("pp_anaglyph_3d_fov", "0", true, false, "FOV for the anaglyph 3D effect. 0 = default FOV", 0, 150)
local pp_anaglyph_3d_crosshair = CreateClientConVar("pp_anaglyph_3d_crosshair", "0", true, false)

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


    local eyeSeparation = pp_anaglyph_3d_eye_separation:GetFloat() / 19.03
    

    -- Prepare view data
    local view = { x=0, y=0, w=ScrW(), h=ScrH(), fov=fov}
	view.drawmonitors = pp_anaglyph_3d_draw_monitors:GetBool()
    view.drawhud = true--pp_anaglyph_3d_draw_hud:GetBool()
    view.dopostprocess = pp_anaglyph_3d_use_postprocess:GetBool()
    view.drawviewmodel = not pp_anaglyph_3d_no_draw_viewmodel:GetBool()

    if pp_anaglyph_3d_fov:GetFloat() > 0 then
        view.viewmodelfov = pp_anaglyph_3d_fov:GetFloat()
    else
        view.viewmodelfov = fov
    end
    
	-- render.Clear(255, 255, 0, 255) -- Clear the screen to black

    -- Left eye (red)
    view.origin = origin - angles:Right() * (eyeSeparation * 0.5)
    
    -- angle turn 1 degree to the left
    view.angles = Angle(angles.p, angles.y - 1, angles.r)
    render.PushRenderTarget(leftRT)
    -- render.Clear(0, 0, 0, 255)

    render.RenderView(view)
    render.PopRenderTarget()

    -- Right eye (blue)

    view.origin = origin + angles:Right() * (eyeSeparation * 0.5)
    -- angle turn 1 degree to the right
    view.angles = Angle(angles.p, angles.y + 1, angles.r)
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

    return false
end)

hook.Add("HUDShouldDraw", "HideCrosshair", function(name)
    if not pp_anaglyph_3d:GetBool() then return end
    if               name == "CHudCrosshair" then
        return pp_anaglyph_3d_crosshair:GetBool()
    end
end)

list.Set( "PostProcess", "Anaglyph 3D", {
	icon		= "materials/gui/anaglyph_3d.png",
	convar = "pp_anaglyph_3d",
	category = "GuuscoNL's Post Process",

    cpanel = function(cPanel)
        local form = vgui.Create("DForm", cPanel)
        form:SetName("Anaglyph 3D")
        cPanel:AddItem(form)

        form:Help("Experience Garry's Mod in advanced 3D technology from the 80s!")

        form:CheckBox("Enable Anaglyph 3D", "pp_anaglyph_3d")
        form:ControlHelp("This will render the world in anaglyph 3D. Use red/cyan glasses to see the effect.")

        form:NumSlider("Eye Separation (mm)", "pp_anaglyph_3d_eye_separation", 0, 100, 0)
        form:ControlHelp("This sets the eye separation in millimeters. Adults typically range from 50-75mm, with 63mm being average. AKA intensity of the 3D effect. Try lowering it if the effect is too strong. Differs per person.")

        form:CheckBox("No Viewmodel", "pp_anaglyph_3d_no_draw_viewmodel")
        form:ControlHelp("This will draw the viewmodel in anaglyph 3D.")

        -- form:CheckBox("Draw HUD", "pp_anaglyph_3d_draw_hud")
        -- form:ControlHelp("This will draw the HUD in anaglyph 3D.")

        form:CheckBox("Draw Monitors", "pp_anaglyph_3d_draw_monitors")
        form:ControlHelp("This will draw monitors such as cameras and TVs while in anaglyph 3D.")

        form:CheckBox("Use Post Process", "pp_anaglyph_3d_use_postprocess")
        form:ControlHelp("This will use post-process effects to draw the anaglyph 3D effect.")

        form:CheckBox("Crosshair", "pp_anaglyph_3d_crosshair")
        form:ControlHelp("This will draw the crosshair in anaglyph 3D mode.")

        form:NumSlider("Viewmodel FOV", "pp_anaglyph_3d_fov", 0, 150, 0)
        form:ControlHelp("Change the viewmodel FOV for the anaglyph 3D effect. Use 0 for default. A higher FOV moves the viewmodel farther from the camera, enhancing the 3D effect. If the viewmodel is too close, the red and cyan images may be too far apart for your eyes to merge comfortably.")
    end
})

print("GUUSCONL POST PROCESS UPADTED")
