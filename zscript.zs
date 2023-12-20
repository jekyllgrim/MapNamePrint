version "4.9"

class JGP_MapStartupInfo : EventHandler
{
	const TITLEEVENTNAME = "printtitle";
	const TITLEVRESX = 320;
	const TITLEVRESY = 200;

	enum EWipeStyle
	{
		WS_None,
		WS_Fade,
		WS_Horizontal,
		WS_Vertical,
		WS_Outward,
	}

	ui uint titleTics;
	ui uint titleDuration;
	ui EWipeStyle startWipeStyle;
	ui EWipeStyle endWipeStyle;
	ui uint startWipeTime;
	ui uint endWipeTime;
	ui uint startWipeThreshold;
	ui uint endWipeThreshold;
	ui color titleColor;
	ui color authorColor;
	ui Font titleFnt;
	ui String t_mapnum;
	ui String t_mapname;
	ui String t_author;

	clearscope double LinearMap(double val, double source_min, double source_max, double out_min, double out_max, bool clampit = false) 
	{
		double d = (val - source_min) * (out_max - out_min) / (source_max - source_min) + out_min;
		if (clampit)
		{
			double truemax = out_max > out_min ? out_max : out_min;
			double truemin = out_max > out_min ? out_min : out_max;
			d = Clamp(d, truemin, truemax);
		}
		return d;
	}

	override void PlayerSpawned(PlayerEvent e)
	{
		SendInterfaceEvent(e.PlayerNumber, TITLEEVENTNAME);
	}

	override void InterfaceProcess (ConsoleEvent e)
	{
		if (e.name == TITLEEVENTNAME)
		{
			CVar show = CVar.GetCVar('mnp_enable', players[consoleplayer]);
			if (!show || !show.GetBool())
			{
				return;
			}
			titleFnt = Font.FindFont('BigUpper');
			if (!titleFnt)
			{
				titleFnt = Font.FindFont('BIGFONT');
			}
			if (!titleFnt)
			{
				Console.Printf("Error: \cDBIGFONT\cG not found; cannot print map name.");
				return;
			}

			t_mapname = StringTable.Localize(Level.levelName);
			if (!t_mapname || t_mapname ~== "TITLEMAP")
			{
				return;
			}

			t_mapnum = CVar.GetCvar('mnp_showmapnum', players[consoleplayer]).GetBool() ? Level.mapName : "";
			if (t_mapname && t_mapnum)
			{
				t_mapname = String.Format("%s: %s", t_mapnum, t_mapname);
			}
			t_author = Level.authorName;

			titleDuration = CVar.GetCvar('mnp_showtime', players[consoleplayer]).GetInt();
			startWipeTime = Clamp(CVar.GetCvar('mnp_fadeintime', players[consoleplayer]).GetInt(), 0, titleDuration * 0.5);
			endWipeTime = Clamp(CVar.GetCvar('mnp_fadeouttime', players[consoleplayer]).GetInt(), 0, titleDuration * 0.5);
			titleDuration += (startWipeTime + endWipeTime);
			startWipeThreshold = titleDuration - startWipeTime;
			endWipeThreshold = endWipeTime;
			titleTics = titleDuration;
			
			startWipeStyle = CVar.GetCvar('mnp_startWipeStyle', players[consoleplayer]).GetInt();
			endWipeStyle = CVar.GetCvar('mnp_endWipeStyle', players[consoleplayer]).GetInt();
			
			color col;
			col = color(CVar.GetCvar('mnp_titlecolor', players[consoleplayer]).GetInt());
			titleColor = color(255, col.r, col.g, col.b);
			col = color(CVar.GetCvar('mnp_authorcolor', players[consoleplayer]).GetInt());
			authorColor = color(255, col.r, col.g, col.b);
			
			//Console.Printf("printing title %s for %d tics", t_mapname, titleTics);
		}
	}

	override void UiTick()
	{
		if (titleTics > 0 && !Menu.GetCurrentMenu())
		{
			titleTics--;
			if (titleTics == 0)
			{
				Screen.ClearClipRect();
			}
		}
	}

	override void RenderOverlay(RenderEvent e)
	{
		if (titleTics <= 0 || gamestate != GS_LEVEL || !t_mapname || !titleFnt)
		{
			return;
		}

		int t_mapname_width = titleFnt.StringWidth(t_mapname);
		int t_author_width = titleFnt.StringWidth(t_author);
		double scale = 1.0;
		double authorscale = scale * 0.65;
		double vPos = TITLEVRESY * 0.2;

		double alpha = 1.0;
		vector2 screenSize = (Screen.GetWidth(), Screen.GetHeight());
		if (startWipeThreshold > 0 && titleTics >= startWipeThreshold)
		{
			double ofs;
			switch (startWipeStyle)
			{
			default:
				break;
			case WS_Fade:
				alpha = LinearMap(titleTics, titleDuration, startWipeThreshold, 0., 1., true);
				break;
			case WS_Horizontal:
				ofs = LinearMap(titleTics, titleDuration, startWipeThreshold, -screenSize.x, 0, true);
				Screen.SetClipRect(ofs, 0, screenSize.x, screenSize.y);
				break;
			case WS_Vertical:
				ofs = LinearMap(titleTics, titleDuration, startWipeThreshold, -screenSize.y * 0.5, 0, true);
				Screen.SetClipRect(0, ofs, screenSize.x, screenSize.y*0.5);
				break;
			case WS_Outward:
				double wipeWidth = LinearMap(titleTics, titleDuration, startWipeThreshold, 0, screenSize.x * 0.5, true);
				Screen.SetClipRect(screenSize.x * 0.5 - wipeWidth * 0.5, 0, wipeWidth, screenSize.y);
				break;
			}
		}
		if (endWipeThreshold > 0 && titleTics <= endWipeThreshold)
		{
			double ofs;
			switch (endWipeStyle)
			{
			default:
				break;
			case WS_Fade:
				alpha = LinearMap(titleTics, endWipeThreshold, 0, 1., 0., true);
				break;
			case WS_Horizontal:
				ofs = LinearMap(titleTics, endWipeThreshold, 0, 0, screenSize.x, true);
				Screen.SetClipRect(ofs, 0, screenSize.x, screenSize.y);
				break;
			case WS_Vertical:
				ofs = LinearMap(titleTics, endWipeThreshold, 0, 0, screenSize.y * 0.5, true);
				Screen.SetClipRect(0, ofs, screenSize.x, screenSize.y*0.5);
				break;
			case WS_Outward:
				double wipeWidth = LinearMap(titleTics, endWipeThreshold, 0, screenSize.x * 0.5, 0, true);
				Screen.SetClipRect(screenSize.x * 0.5 - wipeWidth * 0.5, 0, wipeWidth, screenSize.y);
				break;
			}
		}

		Screen.DrawText(
			titleFnt, Font.CR_Untranslated,
			(TITLEVRESX * 0.5) - (t_mapname_width * 0.5 * scale), vPos,
			t_mapname,
			DTA_Color, titleColor,
			DTA_Alpha, alpha,
			DTA_VirtualWidth, TITLEVRESX,
			DTA_VirtualHeight, TITLEVRESY,
			DTA_ScaleX, scale,
			DTA_ScaleY, scale,
			DTA_FullscreenScale, FSMode_ScaleToFit43
		);

		if (t_author)
		{
			double authorHeight = titleFnt.GetHeight() * authorscale;

			Screen.DrawText(
				titleFnt, Font.CR_Untranslated,
				(TITLEVRESX * 0.5) - (t_author_width * 0.5 * authorscale), vPos + authorHeight,
				t_author,
				DTA_Color, authorColor,
				DTA_Alpha, alpha,
				DTA_VirtualWidth, TITLEVRESX,
				DTA_VirtualHeight, TITLEVRESY,
				DTA_ScaleX, authorscale,
				DTA_ScaleY, authorscale,
				DTA_FullscreenScale, FSMode_ScaleToFit43
			);
		}
		
		Screen.ClearClipRect();
	}
}