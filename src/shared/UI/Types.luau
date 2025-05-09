--!strict
--[[
    Types.luau
    
    Shared type definitions for the UI system.
    These types are used across both client and server scripts.
]]

export type UIComponentProps = {
    name: string,
    visible: boolean?,
    enabled: boolean?,
    parent: Instance?,
    position: UDim2?,
    size: UDim2?,
    anchorPoint: Vector2?,
    backgroundColor3: Color3?,
    backgroundTransparency: number?,
    borderSizePixel: number?,
    borderColor3: Color3?,
    zIndex: number?,
    layoutOrder: number?,
    autoSize: Enum.AutomaticSize?,
    children: {[string]: UIComponentProps}?,
}

export type UIState = {
    visible: boolean,
    enabled: boolean,
    focused: boolean,
    hovered: boolean,
    pressed: boolean,
    selected: boolean,
    loading: boolean,
    error: string?,
}

export type UIAnimation = {
    type: "fade" | "slide" | "scale" | "rotate",
    duration: number,
    easing: Enum.EasingStyle,
    direction: Enum.EasingDirection,
    properties: {[string]: any},
}

export type UIEvent = {
    type: "click" | "hover" | "press" | "release" | "focus" | "blur" | "change",
    target: Instance,
    data: {[string]: any}?,
}

export type UIComponent = {
    -- Properties
    name: string,
    instance: Instance,
    state: UIState,
    props: UIComponentProps,
    
    -- Methods
    show: (self: UIComponent, animation: UIAnimation?) -> (),
    hide: (self: UIComponent, animation: UIAnimation?) -> (),
    update: (self: UIComponent, props: UIComponentProps) -> (),
    destroy: (self: UIComponent) -> (),
    
    -- Event handlers
    onEvent: (self: UIComponent, event: UIEvent) -> (),
}

export type UISystem = {
    -- Properties
    components: {[string]: UIComponent},
    activeComponent: UIComponent?,
    
    -- Methods
    register: (self: UISystem, component: UIComponent) -> (),
    unregister: (self: UISystem, name: string) -> (),
    show: (self: UISystem, name: string, animation: UIAnimation?) -> (),
    hide: (self: UISystem, name: string, animation: UIAnimation?) -> (),
    get: (self: UISystem, name: string) -> UIComponent?,
    
    -- Event handling
    dispatch: (self: UISystem, event: UIEvent) -> (),
}

return nil 