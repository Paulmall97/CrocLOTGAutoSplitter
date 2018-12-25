state("croc", "croc.exe (1634304 bytes)")
{
}

state("croc", "croc.exe (1663488 bytes)")
{
	int currentLevel : 0x31FA94;
	int currentRoom : 0x33D220;
}

state("croc", "CrocD3D.exe (667648 bytes)")
{
}

state("croc", "Definitive Edition 202f46da")
{
}

init
{
	print("croc.exe: 0x" + modules.First().ModuleMemorySize.ToString("X"));
	var firstModule = modules.First();
	var baseAddr = firstModule.BaseAddress;
	int[,] detours;
	switch (firstModule.ModuleMemorySize)
	{
		case 0x348000:
			version = "croc.exe (1634304 bytes)";
			detours = new int[,] { { 0x18F10, 6, 1 }, { 0x19519, 6, 0 }, { 0x19533, 6, 0 } };
			break;
		case 0x353000:
			version = "croc.exe (1663488 bytes)";
			detours = new int[,] { { 0x1A170, 6, 1 }, { 0x1A7AF, 6, 0 }, { 0x1A7D5, 6, 0 } };
			break;
		case 0x25b000:
			version = "CrocD3D.exe (667648 bytes)";
			detours = new int[,] { { 0x1A060, 6, 1 }, { 0x1A669, 6, 0 }, { 0x1A683, 6, 0 } };
			break;
		case 0x235000:
			//Patched Definitive Edition
			version = "Definitive Edition 202f46da";
			detours = new int[,] { { 0xCC360, 6, 1 }, { 0xCCD2C, 5, 0 }, { 0xCCD7A, 5, 0 } };
			break;
		default:
			return;
	}

	var injectMS = new System.IO.MemoryStream();
	var injectBW = new System.IO.BinaryWriter(injectMS);

	// Write initial value of load variable
	injectBW.Write(0);

	// Allocate memory for artificial loading variable and injected code
	var addrInjected = memory.AllocateMemory(4 + detours.GetLength(0) * (10 + 5)); // int32 + n * (mov + jmp)
	if (addrInjected == System.IntPtr.Zero) throw new System.ComponentModel.Win32Exception();
	var addrLoadVar = addrInjected;

	// Prepare injected code and write detours
	for (int i = 0; i < detours.GetLength(0); ++i)
	{
		int relDetourSrc = detours[i, 0], overwrittenBytes = detours[i, 1], val = detours[i, 2];
		var detourDest = addrInjected + (int)injectMS.Length;
		// Write mov <load_var>, <val>
		injectBW.Write(new byte[] { 0xC7, 0x05 }); // mov
		injectBW.Write(addrLoadVar.ToInt32());
		injectBW.Write(val);
		// Write detour to injected code
		var gate = memory.WriteDetour(baseAddr + relDetourSrc, overwrittenBytes, detourDest);
		// Write jmp to gate
		injectBW.Write((byte)0xE9); // jmp
		injectBW.Write(gate.ToInt32() - (addrInjected.ToInt32() + (int)injectMS.Length + 4));
	}

	// Write initial variable value and code to process
	if (!memory.WriteBytes(addrInjected, injectMS.ToArray())) throw new System.ComponentModel.Win32Exception();

	vars.AddrIsLoading = addrLoadVar;
}

split
{
	return false;
}

exit
{
	((IDictionary<string, object>)vars).Remove("AddrIsLoading");
}

isLoading
{
	object addrIsLoading;
	return ((IDictionary<string, object>)vars).TryGetValue("AddrIsLoading", out addrIsLoading) &&
		memory.ReadValue<int>((IntPtr)addrIsLoading) != 0;
}
