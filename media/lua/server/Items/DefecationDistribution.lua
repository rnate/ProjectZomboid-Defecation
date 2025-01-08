local function preDistributionMerge()
    table.insert(ProceduralDistributions.list.BathroomCabinet.items, "Defecation.AntiDiarrhealPill")
	table.insert(ProceduralDistributions.list.BathroomCabinet.items, 1)

	table.insert(ProceduralDistributions.list.BathroomCounter.items, "Defecation.AntiDiarrhealPill")
	table.insert(ProceduralDistributions.list.BathroomCounter.items, 1)

	table.insert(ProceduralDistributions.list.MedicalClinicDrugs.items, "Defecation.AntiDiarrhealPillBox")
	table.insert(ProceduralDistributions.list.MedicalClinicDrugs.items, 2)
	table.insert(ProceduralDistributions.list.MedicalClinicDrugs.items, "Defecation.AntiDiarrhealPillBox")
	table.insert(ProceduralDistributions.list.MedicalClinicDrugs.items, 2)

	table.insert(ProceduralDistributions.list.MedicalStorageDrugs.items, "Defecation.AntiDiarrhealPillBox")
	table.insert(ProceduralDistributions.list.MedicalStorageDrugs.items, 2)
	table.insert(ProceduralDistributions.list.MedicalStorageDrugs.items, "Defecation.AntiDiarrhealPillBox")
	table.insert(ProceduralDistributions.list.MedicalStorageDrugs.items, 2)
end
Events.OnPreDistributionMerge.Add(preDistributionMerge)