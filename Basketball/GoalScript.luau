local hoop=script.Parent.Parent
local brick=script.Parent
local net=hoop.Net

local moveSpeed=0.08	-- How fast the light on the backboard moves.
local netSpeed=0.03	-- How fast the net moves.

local debounce1=0
local debounce2=0

brick.Touched:connect(function(hit) local person=hit.Parent -- Goal Script
	
	if person:IsA("Hat") then
		if person.Parent==workspace then person:Destroy() end
		
	elseif person:IsA("Humanoid"and"Torso") then
		person.Torso.CFrame=hoop.Here.CFrame
		person.Humanoid.Sit=true
		
	elseif person:IsA("Tool") and debounce1==0 then
		debounce1=1
		hoop.Top.PointLight.Enabled=true
		repeat wait(moveSpeed)
			hoop.Top.Transparency=hoop.Top.Transparency-0.1
		until hoop.Top.Transparency<=0.1
		repeat wait(moveSpeed)
			hoop.Top.Transparency=hoop.Top.Transparency+0.1
		until hoop.Top.Transparency>=1
		hoop.Top.PointLight.Enabled=false
		wait(0.1)
	end
	
	debounce1=0
end)

brick.Touched:connect(function(hit) local person1=hit.Parent -- Swish Script
	
	if person1:IsA("Tool") and debounce2==0 then
		debounce2=1
		if hoop.swish.Value==false then
			
			net.Mesh.Scale=Vector3.new(2.4,2.7,2.4) wait(netSpeed)
			net.Mesh.Scale=Vector3.new(2.4,2.4,2.4) wait(netSpeed)
			net.Mesh.Scale=Vector3.new(2.4,2.1,2.4) wait(netSpeed)
			net.Mesh.Scale=Vector3.new(2.4,1.8,2.4) wait(netSpeed)
			net.Mesh.Scale=Vector3.new(2.4,1.5,2.4) wait(netSpeed)
			net.Mesh.Scale=Vector3.new(2.4,1.9,2.4) wait(netSpeed)
			net.Mesh.Scale=Vector3.new(2.4,2.3,2.4) wait(netSpeed)
			net.Mesh.Scale=Vector3.new(2.4,2.7,2.4) wait(netSpeed)
			net.Mesh.Scale=Vector3.new(2.4,3.2,2.4) wait(netSpeed)
			net.Mesh.Scale=Vector3.new(2.4,2.7,2.4) wait(netSpeed)
			
		elseif hoop.swish.Value==true then
			
			person1.Handle.CFrame=brick.CFrame-Vector3.new(0,3,0)
			net.Mesh.Scale=Vector3.new(2.4,-3,2.4) wait(netSpeed)
			net.Mesh.Scale=Vector3.new(2.4,-2.5,2.4) wait(netSpeed)
			net.Mesh.Scale=Vector3.new(2.4,-2.2,2.4) wait(netSpeed)
			net.Mesh.Scale=Vector3.new(2.4,-1.9,2.4) wait(netSpeed)
			net.Mesh.Scale=Vector3.new(2.4,-1.4,2.4) wait(netSpeed)
			net.Mesh.Scale=Vector3.new(2.4,-1,2.4) wait(netSpeed)
			net.Mesh.Scale=Vector3.new(2.4,-0.5,2.4) wait(netSpeed)
			net.Mesh.Scale=Vector3.new(2.4,0.4,2.4) wait(netSpeed)
			net.Mesh.Scale=Vector3.new(2.4,0.9,2.4) wait(netSpeed)
			net.Mesh.Scale=Vector3.new(2.4,1.5,2.4) wait(netSpeed)
			net.Mesh.Scale=Vector3.new(2.4,2,2.4) wait(netSpeed)
			net.Mesh.Scale=Vector3.new(2.4,2.4,2.4) wait(netSpeed)
			net.Mesh.Scale=Vector3.new(2.4,2.9,2.4) wait(netSpeed)
			net.Mesh.Scale=Vector3.new(2.4,3.2,2.4) wait(netSpeed)
			net.Mesh.Scale=Vector3.new(2.4,2.7,2.4) wait(netSpeed)
			
		end
	end
	debounce2=0
end)
