state("croc")
{
	int currentLevel : 0x31FA94;
}

startup
{
  vars.highestLevel = 0;
	vars.levels = new string[] {
		"1:1", "1:2", "1:3", "1:B1", "1:S1", "1:4", "1:5", "1:6", "1:B2", "1:S2",
		"2:1", "2:2", "2:3", "2:B1", "2:S1", "2:4", "2:5", "2:6", "2:B2", "2:S2",
		"3:1", "3:2", "3:3", "3:B1", "3:S1", "3:4", "3:5", "3:6", "3:B2", "3:S2",
		"4:1", "4:2", "4:3", "4:B1", "4:S1", "4:4", "4:5", "4:6", "4:B2", "4:S2",
		"5:1", "5:2", "5:3", "5:4", "5:B"};

	foreach (string element in vars.levels)
	{
		settings.Add(element, true, element);
	}

}

start
{
  if(current.currentLevel == 0 && current.currentLevel != old.currentLevel){
    return true;
  }
  vars.highestLevel = 0;
}

split
{
	//check if a level was just completed
  if(current.currentLevel > old.currentLevel && current.currentLevel > vars.highestLevel){

		//get how many levels we just skipped (used when games counter skips puzzle levels)
		int previous = current.currentLevel - old.currentLevel;

		//check if we split for that level
		if(settings[vars.levels[current.currentLevel - previous]])
		{
			//split
			vars.highestLevel = current.currentLevel;
	    return true;
		}

  }
}
