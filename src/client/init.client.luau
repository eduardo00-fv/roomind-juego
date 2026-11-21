--!strict
-- Cliente: escucha los portales de la plaza y corre el minijuego que toque.
-- Cada juego vive en src/client/Juegos/<id>.luau y exporta jugar(ctx) -> completo.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Modulos = require(ReplicatedStorage.Shared.Modulos)
local Interfaz = require(script.Interfaz)

local Juegos: { [string]: any } = {
	lava = require(script.Juegos.Lava),
}

local partida = ReplicatedStorage:WaitForChild("Partida") :: RemoteEvent
local jugador = Players.LocalPlayer
local enJuego = false
local avisado: { [string]: number } = {}

local ctx = {
	reto = function(datos: { [string]: any })
		partida:FireServer("reto", datos)
	end,
}

local function entrar(id: string, alfombra: BasePart)
	if enJuego then
		return
	end
	local juego = Juegos[id]
	if not juego then
		if os.clock() - (avisado[id] or -10) > 4 then
			avisado[id] = os.clock()
			Interfaz.mensaje(Modulos[id].nombre .. " está en construcción. ¡Probá la lava!", nil, 3)
		end
		return
	end
	enJuego = true
	partida:FireServer("empezar", id)
	local ok, completo = pcall(juego.jugar, ctx)
	if not ok then
		warn("[" .. id .. "] " .. tostring(completo))
		completo = false
	end
	partida:FireServer("terminar", completo == true)
	-- De vuelta a la plaza, unos pasos delante del portal y mirando al centro.
	Interfaz.telon("De vuelta a la plaza", function()
		local ch = jugador.Character
		if ch then
			local p = alfombra.Position * Vector3.new(0.7, 0, 0.7) + Vector3.new(0, 4, 0)
			ch:PivotTo(CFrame.lookAt(p, Vector3.new(0, 4, 0)))
		end
	end)
	task.wait(1)
	enJuego = false
end

local function conectar(alfombra: Instance)
	if not alfombra:IsA("BasePart") then
		return
	end
	local id = alfombra:GetAttribute("Modulo")
	if type(id) ~= "string" then
		return
	end
	alfombra.Touched:Connect(function(otro)
		local ch = jugador.Character
		if ch and otro:IsDescendantOf(ch) then
			task.spawn(entrar, id, alfombra)
		end
	end)
end

for _, a in CollectionService:GetTagged("Portal") do
	conectar(a)
end
CollectionService:GetInstanceAddedSignal("Portal"):Connect(conectar)
