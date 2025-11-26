ENT.Base = "base_gmodentity"
ENT.Type = "anim"
ENT.PrintName = "Money Printer"
ENT.Category = "Dubz Money Printers"
ENT.Author = "BDubz420"
ENT.Spawnable = true
ENT.Model = "models/dubz_props/dubz_printer.mdl"  -- Change this to your preferred ATM model

function ENT:SetupDataTables()
	self:NetworkVar( "Entity", 0, "owning_ent" )
end