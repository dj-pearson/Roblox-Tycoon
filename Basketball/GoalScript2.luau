function onTouched(hit)
	script.Parent.Swish:play()
end
script.Parent.Touched:connect(onTouched)