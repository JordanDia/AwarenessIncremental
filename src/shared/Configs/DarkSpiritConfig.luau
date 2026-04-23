local RunService = game:GetService("RunService")

-- Numbers use the same suffix scale as FormatNumber (K=1e3, M=1e6, B=1e9, T=1e12, Qa=1e15, Qi=1e18, S=1e21)
return {
    SpawnCost = {
        Essences    = 200,
        Awareness   = 1e21,   -- 1S
        Crystals    = 100e9,  -- 100B
        AstralEchoes = 5e9,   -- 5B
        Rebirths    = 1e21,   -- 1S
    },

    -- If true, all requirements are bypassed (cost still deducted)
    --FreeInStudio = RunService:IsStudio(),
    FreeInStudio = false,
}
