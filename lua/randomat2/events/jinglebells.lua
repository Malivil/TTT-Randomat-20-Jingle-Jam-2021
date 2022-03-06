local EVENT = {}

EVENT.Title = "Jingle Bells"
EVENT.Description = "Jingle all the way!"
EVENT.id = "jinglebells"
EVENT.Categories = {"fun", "smallimpact"}

local footsteps = {
    Sound("lootgoblin/jingle1.wav"),
    Sound("lootgoblin/jingle2.wav"),
    Sound("lootgoblin/jingle3.wav"),
    Sound("lootgoblin/jingle4.wav"),
    Sound("lootgoblin/jingle5.wav"),
    Sound("lootgoblin/jingle6.wav"),
    Sound("lootgoblin/jingle7.wav"),
    Sound("lootgoblin/jingle8.wav")
}
function EVENT:Begin()
    self:AddHook("PlayerFootstep", function(ply, pos, foot, snd, volume, rf)
        local idx = math.random(1, #footsteps)
        local chosen_sound = footsteps[idx]
        sound.Play(chosen_sound, pos, volume, 100, 1)
    end)
end

function EVENT:Condition()
    return ROLE_LOOTGOBLIN and ROLE_LOOTGOBLIN > ROLE_NONE
end

Randomat:register(EVENT)