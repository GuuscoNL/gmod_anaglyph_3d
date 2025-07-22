--#TODO: Dubois algorithm to help against ghosting and color accuracy issues, but needs shader support...


local pp_anaglyph_3d = CreateClientConVar("pp_anaglyph_3d", "0", false, false)
local pp_anaglyph_3d_eye_separation = CreateClientConVar("pp_anaglyph_3d_eye_separation", "63", true, false, "millimeters (63 is average for adults and in the range of 50-75)", 0, 100)
local pp_anaglyph_3d_no_draw_viewmodel = CreateClientConVar("pp_anaglyph_3d_no_draw_viewmodel", "0", true, false)
-- local pp_anaglyph_3d_draw_hud = CreateClientConVar("pp_anaglyph_3d_draw_hud", "1", true, false)
local pp_anaglyph_3d_draw_monitors = CreateClientConVar("pp_anaglyph_3d_draw_monitors", "1", true, false)
local pp_anaglyph_3d_use_postprocess = CreateClientConVar("pp_anaglyph_3d_use_postprocess", "1", true, false)
local pp_anaglyph_3d_fov = CreateClientConVar("pp_anaglyph_3d_fov", "0", true, false, "FOV for the anaglyph 3D effect. 0 = default FOV", 0, 150)
local pp_anaglyph_3d_crosshair = CreateClientConVar("pp_anaglyph_3d_crosshair", "0", true, false)
local pp_anaglyph_3d_crosseyedness = CreateClientConVar("pp_anaglyph_3d_crosseyedness", "0.6", true, false, "Crosseyedness in degrees", 0, 5)
local pp_anaglyph_3d_brightness = CreateClientConVar("pp_anaglyph_3d_brightness", "1", true, false, "Brightness of the anaglyph 3D effect. 0 = blackscreen, 1 = normal brightness, 2 = double brightness", 0, 10)
local pp_anaglyph_3d_eye_position = CreateClientConVar("pp_anaglyph_3d_eye_position", "1", true, false, "Eye position: Left eye, middle, Right eye", 0, 2)


-- Create RTs
local leftRT  = GetRenderTarget(
	"AnaglyphLeftRT",  
	ScrW(), ScrH())

local rightRT = GetRenderTarget(
	"AnaglyphRightRT",  
	ScrW(), ScrH())


-- Create materials
local matRed = CreateMaterial("AnaglyphLeftRed", "UnlitGeneric", {
    ["$basetexture"]     = leftRT:GetName(),
    ["$translucent"]     = "1",
    ["$color"]           = "[1 0 0]" -- Only store red
})

-- Blue‑only version of right RT
local matBlue = CreateMaterial("AnaglyphRightBlue", "UnlitGeneric", {
    ["$basetexture"]     = rightRT:GetName(),
    ["$translucent"]     = "1",
    ["$color"]           = "[0 1 1]" -- Only store green and blue (cyan)
})



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

    local eyePosition = pp_anaglyph_3d_eye_position:GetInt()

    -- Left eye (red)
    view.origin = origin - angles:Right() * ( (eyeSeparation * 0.5) * eyePosition )
    view.angles = Angle(angles.p, angles.y - pp_anaglyph_3d_crosseyedness:GetFloat(), angles.r)
    render.PushRenderTarget(leftRT)
    render.Clear(0, 0, 0, 255) -- Clear the render target to black

    render.RenderView(view)
    render.PopRenderTarget()

    
    -- Right eye (blue)
    view.origin = origin + angles:Right() *( (eyeSeparation * 0.5) * (2-eyePosition))
    view.angles = Angle(angles.p, angles.y + pp_anaglyph_3d_crosseyedness:GetFloat(), angles.r)
    render.PushRenderTarget(rightRT)
    render.Clear(0, 0, 0, 255) -- Clear the render target to black
    
    local ply = LocalPlayer()

    hook.Run("CalcView", ply, origin, angles, fov)
    
    render.RenderView(view)
    render.PopRenderTarget()


    -- Render the left and right RTs to the screen
    matRed:SetVector("$color", Vector(pp_anaglyph_3d_brightness:GetFloat(), 0, 0))
    matBlue:SetVector("$color", Vector(0, pp_anaglyph_3d_brightness:GetFloat(), pp_anaglyph_3d_brightness:GetFloat()))
    cam.Start2D()
    
        render.OverrideBlend(true, BLEND_ONE, BLEND_ONE, BLENDFUNC_ADD)
        
        surface.SetDrawColor(255,255,255,255)
        
        surface.SetMaterial(matRed)
        surface.DrawTexturedRect(0, 0, ScrW(), ScrH())
        
        surface.SetMaterial(matBlue)
        surface.DrawTexturedRect(0, 0, ScrW(), ScrH())
        render.OverrideBlend(false)

    cam.End2D()
    
    
    return true  -- fully override default scene 
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
        form:SetName("Anaglyph 3D Settings")


        local params = { Options = {}, CVars = {}, MenuButton = "1", Folder = "anaglyph_3D" }
		params.Options[ "#preset.default" ] = {
            pp_anaglyph_3d_eye_separation       = "63",
            pp_anaglyph_3d_no_draw_viewmodel    = "0",
            pp_anaglyph_3d_draw_monitors        = "1",
            pp_anaglyph_3d_use_postprocess      = "1",
            pp_anaglyph_3d_fov                  = "0",
            pp_anaglyph_3d_crosshair            = "0",
            pp_anaglyph_3d_crosseyedness        = "0.6",
            pp_anaglyph_3d_brightness           = "1",
            pp_anaglyph_3d_eye_position        = "1"
		}
        params.Options[ "First person shooter" ] = {
            pp_anaglyph_3d_eye_separation       = "14",
            pp_anaglyph_3d_no_draw_viewmodel    = "0",
            pp_anaglyph_3d_draw_monitors        = "1",
            pp_anaglyph_3d_use_postprocess      = "1",
            pp_anaglyph_3d_fov                  = "0",
            pp_anaglyph_3d_crosshair            = "0",
            pp_anaglyph_3d_crosseyedness        = "0.6",
            pp_anaglyph_3d_brightness           = "1",
            pp_anaglyph_3d_eye_position        = "2"
		}

        
        cPanel:AddControl("label", {text = "Experience Garry's Mod in advanced 3D technology from the 80s!\nUse red/cyan glasses to see the effect.\n\nThere is a First Person Shooter preset available to look through iron sights and scopes for most SWEPS."})
        cPanel:AddControl("ComboBox", params)

        
        cPanel:AddControl("CheckBox", {
            Label = "Enable Anaglyph 3D",
            command = "pp_anaglyph_3d"
        })
        cPanel:AddControl("Label", {
            Text = "This will render the world in anaglyph 3D. Use red/cyan glasses to see the effect."
        })

        cPanel:AddItem(form)
        
        form:NumSlider("Eye Separation (mm)", "pp_anaglyph_3d_eye_separation", 0, 100, 0)
        form:ControlHelp("This sets the eye separation in millimeters. Adults typically range from 50-75mm, with 63mm being average. Try lowering it if the effect is too strong. Differs per person. \nNOTE: For weapon SWEPS you might want to lower this to like 12, otherwise the weapon images may be too far apart to merge comfortably.")

        form:NumSlider("Crosseyedness (degrees)", "pp_anaglyph_3d_crosseyedness", 0, 5, 2)
        form:ControlHelp("This sets the crosseyedness in degrees. This is the angle at which the eyes are turned inward to focus on an object, causing distant objects to look distant. A higher value will make the effect more pronounced, but may cause discomfort. Recommended to keep it between 0 and 1.5 degrees.")
        
        -- form:CheckBox("Draw HUD", "pp_anaglyph_3d_draw_hud")
        -- form:ControlHelp("This will draw the HUD in anaglyph 3D.")

        form:NumSlider("Brightness", "pp_anaglyph_3d_brightness", 0, 10, 1)
        form:ControlHelp("This sets the brightness of the anaglyph 3D effect. Because some maps have a dark tint. 0 = blackscreen, 1 = normal brightness, 2 = double brightness.")

        local combobox = form:ComboBox("Eye Position", "pp_anaglyph_3d_eye_position")
        combobox:AddChoice("Left Eye", 0)
        combobox:AddChoice("Middle", 1)
        combobox:AddChoice("Right Eye", 2)
        form:ControlHelp("This sets the eye position for the anaglyph 3D effect. Left eye, middle, or right eye. This is useful for iron sights and scopes in SWEPS. If you select the Right Eye the weapons iron sight will be aligned with the right eye.")

        form:CheckBox("Draw Monitors", "pp_anaglyph_3d_draw_monitors")
        form:ControlHelp("This will draw monitors such as cameras and TVs while in anaglyph 3D.")
        
        form:CheckBox("Crosshair", "pp_anaglyph_3d_crosshair")
        form:ControlHelp("This will draw the crosshair in anaglyph 3D mode.")
        
        form:CheckBox("Use Post Process", "pp_anaglyph_3d_use_postprocess")
        form:ControlHelp("This will use post-process effects to draw the anaglyph 3D effect.")
        
        form:CheckBox("No Viewmodel", "pp_anaglyph_3d_no_draw_viewmodel")
        form:ControlHelp("This will not draw the viewmodel in anaglyph 3D mode.")

        form:NumSlider("Viewmodel FOV", "pp_anaglyph_3d_fov", 0, 150, 0)
        form:ControlHelp("Change the viewmodel FOV for the anaglyph 3D effect. Use 0 for default. A higher FOV moves the viewmodel farther from the camera, enhancing the 3D effect. If the viewmodel is too close, the red and cyan images may be too far apart for your eyes to merge comfortably.")
    end
})
