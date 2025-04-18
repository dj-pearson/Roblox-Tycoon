name = "Basketball" 
debounce = false 

chaching = script.Parent.bounce

function onTouched(hit) 

if (debounce==false) and (hit.Parent.Name==name) then 

debounce = true 

chaching:play()

debounce = false 

end 
end 

script.Parent.Touched:connect(onTouched) 
 