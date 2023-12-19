version "4.9"

class JGP_MapStartupInfo : EventHandler
{
	const TITLEEVENTNAME = "printtitle";
	const TITLEVRESX = 320;
	const TITLEVRESY = 200;

	ui uint titleTics;
	ui uint titleFadeOutTime;
	ui color titleColor;
	ui color authorColor;
	ui Font titleFnt;
	ui String t_mapnum;
	ui String t_mapname;
	ui String t_author;

	override void PlayerSpawned(PlayerEvent e)
	{
		SendInterfaceEvent(e.PlayerNumber, TITLEEVENTNAME);
	}

	override void InterfaceProcess (ConsoleEvent e)
	{
		if (e.name == TITLEEVENTNAME)
		{
			titleTics = CVar.GetCvar('mnp_showtime', players[consoleplayer]).GetInt();
			titleFadeOutTime = Clamp(CVar.GetCvar('mnp_fadeouttime', players[consoleplayer]).GetInt(), 0, titleTics * 0.5);
			titleTics += titleFadeOutTime;
			
			titleColor = color(CVar.GetCvar('mnp_titlecolor', players[consoleplayer]).GetInt());
			authorColor = color(CVar.GetCvar('mnp_authorcolor', players[consoleplayer]).GetInt());
			
			t_mapnum = CVar.GetCvar('mnp_showmapnum', players[consoleplayer]).GetBool() ? Level.mapName : "";
			t_mapname = StringTable.Localize(Level.levelName);
			t_author = Level.authorName;
			if (t_mapname && t_mapnum)
			{
				t_mapname = String.Format("%s: %s", t_mapnum, t_mapname);
			}
			Console.Printf("printing title %s for %d tics", t_mapname, titleTics);
		}
	}

	override void UiTick()
	{
		if (titleTics > 0)
		{
			titleTics--;
		}
	}

	override void RenderOverlay(RenderEvent e)
	{
		if (titleTics <= 0)
			return;
		
		if (!titleFnt)
			titleFnt = Font.FindFont('BigUpper');

		int t_mapname_width = titleFnt.StringWidth(t_mapname);
		int t_author_width = titleFnt.StringWidth(t_author);
		double scale = 1.0;
		double alpha = Clamp(titleTics / double(titleFadeOutTime), 0.0, 1.0);
		double vPos = TITLEVRESY * 0.2;

		Screen.DrawText(
			titleFnt, Font.CR_Untranslated,
			(TITLEVRESX * 0.5) - (t_mapname_width * 0.5 * scale), vPos,
			t_mapname,
			DTA_Color, color(255, titleColor.r, titleColor.g, titleColor.b),
			DTA_Alpha, alpha,
			DTA_VirtualWidth, TITLEVRESX,
			DTA_VirtualHeight, TITLEVRESY,
			DTA_ScaleX, scale,
			DTA_ScaleY, scale,
			DTA_FullscreenScale, FSMode_ScaleToFit43
		);

		if (!t_author)
			return;
		
		scale *= 0.65;
		double authorHeight = titleFnt.GetHeight() * scale;

		Screen.DrawText(
			titleFnt, Font.CR_Untranslated,
			(TITLEVRESX * 0.5) - (t_author_width * 0.5 * scale), vPos + authorHeight,
			t_author,
			DTA_Color, color(255, authorColor.r, authorColor.g, authorColor.b),
			DTA_Alpha, alpha,
			DTA_VirtualWidth, TITLEVRESX,
			DTA_VirtualHeight, TITLEVRESY,
			DTA_ScaleX, scale,
			DTA_ScaleY, scale,
			DTA_FullscreenScale, FSMode_ScaleToFit43
		);
	}
}