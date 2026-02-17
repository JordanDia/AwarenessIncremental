return {

    Tree1 = {
        {
            NodeId = "RootNode",
            Unlocks = {"NodeA"},
            UnlockLinks = {1},
            Rewards = {"Crystals"},

            Title = "Upgrade: 1-1",
            UpgradeName = "Unlock Crystal Collection",
            Cost = {
                Amount = 5,
                Currency = "Awareness",
            }
            
        },


        {
            NodeId = "NodeA",
            Unlocks = {"NodeB"},
            UnlockLinks = {2},
            Rewards = {"2x Awareness"},

            Title = "Upgrade: 1-2",
            UpgradeName = "2x Awareness",
            Cost = {
                Amount = 20,
                Currency = "Crystals",
            }
        },

        {
            NodeId = "NodeB",
            Unlocks = {"NodeC"},
            UnlockLinks = {3},
            Rewards = {"2x Rebirths"},

            Title = "Upgrade: 1-3",
            UpgradeName = "2x Rebirths",
            Cost = {
                Amount = 200,
                Currency = "Crystals",
            }
        },

        {
            NodeId = "NodeC",
            Unlocks = {},
            UnlockLinks = {},
            Rewards = {"2x Crystals"},

            Title = "Upgrade: 1-4",
            UpgradeName = "2x Crystals",
            Cost = {
                Amount = 500,
                Currency = "Crystals",
            }
        },

    }
    
}