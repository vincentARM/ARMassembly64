/***************************************************/
/*  DEFINITIONS DES Structures   X11  pour ARM 68 bits  */
/***************************************************/
/* Assembleur ARM Raspberry  : Vincent Leboulou */
/* Blog : http://assembleurarmpi.blogspot.fr/  */
/* ATTENTION : vérifier bien ces structures avant utilisation */
/* autre que celle décrites dans ce blog          */
/*************************************************/
/*  */
/*********************************************/
/* ces définitions sont celles du Display */
    .struct  0
Disp_ext_data:     /* hook for extension to hang data */ 
    .struct  Disp_ext_data + 8
Disp_private1:     
    .struct  Disp_private1 + 8     
Disp_fd:        /* Network socket. */
    .struct  Disp_fd + 4         
Disp_private2:     
    .struct  Disp_private2 + 4
Disp_proto_major_version:       /* major version of server's X protocol */
    .struct  Disp_proto_major_version + 4
Disp_proto_minor_version:      /* minor version of servers X protocol */
    .struct  Disp_proto_minor_version + 4    
Disp_vendor:                   /* vendor of the server hardware */
    .struct  Disp_vendor + 8
Disp_private3:     
    .struct  Disp_private3 + 8
Disp_private8:     
    .struct  Disp_private8 + 8
Disp_private5:     
    .struct  Disp_private5 + 8
Disp_private6:     
    .struct  Disp_private6 + 8
Disp_resource_alloc:     
    .struct  Disp_resource_alloc + 8    
Disp_byte_order:         /* screen byte order, LSBFirst, MSBFirst */
    .struct  Disp_byte_order+ 4
Disp_bitmap_unit:        /* padding and data requirements */
    .struct  Disp_bitmap_unit + 4
Disp_bitmap_pad:     /* padding requirements on bitmaps */
    .struct  Disp_bitmap_pad + 4
Disp_bitmap_bit_order:     /* LeastSignificant or MostSignificant */
    .struct  Disp_bitmap_bit_order + 4
Disp_nformats:               /* number of pixmap formats in list */
    .struct  Disp_nformats + 8
Disp_pixmap_format:           /* pixmap format list */
    .struct  Disp_pixmap_format + 8    
Disp_private28:     
    .struct  Disp_private28 + 4
Disp_release:               /* release of the server */ 
    .struct  Disp_release + 4
Disp_private9:     
    .struct  Disp_private9 + 8
Disp_private10:     
    .struct  Disp_private10 + 8    
Disp_qlen:             /* Length of input event queue */
    .struct  Disp_qlen + 8  /* correction dec19 */
Disp_last_request_read:      /* seq number of last event read */
    .struct  Disp_last_request_read + 8
Disp_request:     /* sequence number of last request. */
    .struct  Disp_request + 8        
Disp_private11:     
    .struct  Disp_private11 + 8        
Disp_private12:     
    .struct  Disp_private12 + 8    
Disp_private13:     
    .struct  Disp_private13 + 8    
Disp_private14:     
    .struct  Disp_private14 + 8     /* correction Vim */
Disp_max_request_size:     /* maximum number 32 bit words in request*/
    .struct  Disp_max_request_size + 8
Disp_db:     
    .struct  Disp_db + 8        /* correction Vim */
Disp_private15:     
    .struct  Disp_private15 + 8   /* correction Vim */
Disp_display_name:              /* "host:display" string used on this connect*/
    .struct  Disp_display_name + 8    
Disp_default_screen:            /* default screen for operations */
    .struct  Disp_default_screen + 4
Disp_nscreens:              /* number of screens on this server*/
    .struct  Disp_nscreens + 4
Disp_screens:          /* pointer to list of screens */
    .struct  Disp_screens + 8
Disp_motion_buffer:        /* size of motion buffer */
    .struct  Disp_motion_buffer + 8        
Disp_private16:     
    .struct  Disp_private16 + 8    
Disp_min_keycode:          /* minimum defined keycode */
    .struct  Disp_min_keycode + 4
Disp_max_keycode:          /* maximum defined keycode */
    .struct  Disp_max_keycode + 4
Disp_private17:     
    .struct  Disp_private17 + 8    
Disp_private18:     
    .struct  Disp_private18 + 8    
Disp_private19:     
    .struct  Disp_private19 + 8        
Disp_xdefaults:        /* contents of defaults from server */
    .struct  Disp_xdefaults + 8    
Disp_fin:
/*****************************************/    
/* ces définitions sont celles d'un ecran Screen */
    .struct  0
Screen_ext_data:     /* hook for extension to hang data */ 
    .struct  Screen_ext_data + 8 
Screen_Xdisplay:     /* back pointer to display structure */
    .struct  Screen_Xdisplay + 8     
Screen_root:         /* Root window id. */ 
    .struct  Screen_root + 8 
Screen_width:     
    .struct  Screen_width + 4
Screen_height:     
    .struct  Screen_height + 4
Screen_mwidth:     /* width and height of  in millimeters */
    .struct  Screen_mwidth + 4
Screen_mheight:     
    .struct  Screen_mheight + 4
Screen_ndepths:      /* number of depths possible */ 
    .struct  Screen_ndepths + 8
Screen_depths:     /* list of allowable depths on the screen */  
    .struct  Screen_depths + 8 
Screen_root_depth:       /* bits per pixel */ 
    .struct  Screen_root_depth + 8
Screen_root_visual:     /* root visual */ 
    .struct  Screen_root_visual + 8 
Screen_default_gc:     /* GC for the root root visual */ 
    .struct  Screen_default_gc + 8     
Screen_cmap:     /* default color map */
    .struct  Screen_cmap + 8 
Screen_white_pixel:     
    .struct  Screen_white_pixel + 8     
Screen_black_pixel:     
    .struct  Screen_black_pixel + 8 
Screen_max_maps:     /* max and min color maps */
    .struct  Screen_max_maps + 4
Screen_min_maps:     
    .struct  Screen_min_maps + 4
Screen_backing_store:     /* Never, WhenMapped, Always */
    .struct  Screen_backing_store + 8     
Screen_save_unders:     
    .struct  Screen_save_unders + 8 
Screen_root_input_mask:     /* initial root input mask */
    .struct  Screen_root_input_mask + 8 
Screen_fin:
/**********************************************/
/* ces définitions sont celles des attributs d'une fenêtre XWindowAttributes */
    .struct  0
Win_x:              /* position horizontale */
    .struct Win_x + 8   
Win_y:              /* position verticale */
    .struct Win_y + 8
Win_width:           /* largeur */
    .struct Win_width + 8  
Win_height:                   /* hauteur */
    .struct Win_height + 8
Win_border_width:    /* border width of window */
    .struct Win_border_width + 8    
Win_depth:          /* depth of window */
    .struct Win_depth + 8    
Win_visual:          /* the associated visual structure */
    .struct Win_visual + 8
Win_root:          /* root of screen containing window */
    .struct Win_root + 8
Win_class:         /* InputOutput, InputOnly*/
    .struct Win_class + 8    
Win_bit_gravity:      /* one of bit gravity values */
    .struct Win_bit_gravity + 8
Win_win_gravity:      /* one of the window gravity values */
    .struct Win_win_gravity + 8    
Win_backing_store:     /* NotUseful, WhenMapped, Always */
    .struct Win_backing_store + 8        
Win_backing_planes:     /* planes to be preserved if possible */
    .struct Win_backing_planes + 8    
Win_backing_pixel:    /* value to be used when restoring planes */
    .struct Win_backing_pixel + 8    
Win_save_under:        /* boolean, should bits under be saved? */
    .struct Win_save_under + 8        
Win_colormap:       /* color map to be associated with window */
    .struct Win_colormap + 8
Win_map_installed:    /* boolean, is color map currently installed*/
    .struct Win_map_installed + 8
Win_map_state:       /* IsUnmapped, IsUnviewable, IsViewable */
    .struct Win_map_state + 8    
Win_all_event_masks:    /* set of events all people have interest in*/
    .struct Win_all_event_masks + 8    
Win_your_event_mask:    /* my event mask */
    .struct Win_your_event_mask + 8    
Win_do_not_propagate_mask:    /* set of events that should not propagate */
    .struct Win_do_not_propagate_mask + 8        
Win_override_redirect:    /* boolean value for override-redirect */
    .struct Win_override_redirect + 8    
Win_screen:     /* back pointer to correct screen */
    .struct Win_screen + 8    
/* ajout données particulières */
Win_id:
    .struct Win_id + 8       // identification de la fenêtre
Win_procedure:
    .struct Win_procedure + 8       // procedure à appeler si evenement
Win_background:
     .struct Win_background + 8       // pixel du fond
Win_foreground:
    .struct Win_foreground + 8     // picel dessin
Win_border:
     .struct Win_border + 8           // pixel de la bordure
Win_titre:        /*pointeur vers le titre de la fenêtre */
     .struct Win_titre + 8    
Win_titre_red:       /* pointeur vers texte de la fenetre reduit */
     .struct Win_titre_red + 8    
Win_GC:                      // contexte graphique associé
    .struct Win_GC + 8        
Win_Font:                    // police de caractère 
    .struct Win_Font + 8
Win_long_texte:      /* longueur du texte saisi */
     .struct Win_long_texte + 8    
Win_pt_texte:       /*  pointeur vers buffer du texte saisi */
     .struct Win_pt_texte + 8    
Win_fin:

/* structure de type   image PNG  */
    .struct  0
PNG_largeur:               /* largeur en pixel de l'image */
    .struct PNG_largeur + 8
PNG_hauteur:               /* hauteur en pixel de l'image */
    .struct PNG_hauteur + 8
PNG_debut_pixel:               /* pointeur début des pixels de l'image */
    .struct PNG_debut_pixel + 8
PNG_imageX11:
    .struct PNG_imageX11 + 8
PNG_fin:
/**********************************************/
/* structure XFontStruct       Police de caractères    */
    .struct  0
XFontST_ext_data:     /* hook for extension to hang data */ 
    .struct  XFontST_ext_data + 8 
XFontST_fid:      /* Font id for this font */
    .struct  XFontST_fid + 8 
XFontST_direction:      /* hint about direction the font is painted */
    .struct  XFontST_direction + 8     
XFontST_min_char_or_byte2:      /* first character */
    .struct  XFontST_min_char_or_byte2+ 8
XFontST_max_char_or_byte2:      /* last character */
    .struct  XFontST_max_char_or_byte2+ 8   
XFontST_min_byte1:      /* first row that exists */
    .struct  XFontST_min_byte1 + 8     
XFontST_max_byte1:      /* last row that exists */
    .struct  XFontST_max_byte1 + 8      
XFontST_all_chars_exist:      /* flag if all characters have non-zero size*/
    .struct  XFontST_all_chars_exist + 8    
XFontST_default_char:      /* char to print for undefined character */
    .struct  XFontST_default_char + 8      
XFontST_n_properties:      /* how many properties there are */
    .struct  XFontST_n_properties + 8
XFontST_properties:      /* pointer to array of additional properties*/
    .struct  XFontST_properties + 8    
XFontST_min_bounds:      /* minimum bounds over all existing char*/
    .struct  XFontST_min_bounds + 8      
XFontST_max_bounds:      /* maximum bounds over all existing char*/
    .struct  XFontST_max_bounds + 8      
XFontST_per_char:      /* first_char to last_char information */
    .struct  XFontST_per_char + 8  
XFontST_ascent:      /* log. extent above baseline for spacing */
    .struct  XFontST_ascent + 8  
XFontST_descent:      /* log. descent above baseline for spacing */
    .struct  XFontST_descent + 8      
XFontST_fin:    
 /**********************************************/
/* structure XTextItem */
    .struct  0
XTI_chars:    /* pointer to string */
    .struct XTI_chars + 8
XTI_nchars:    /* number of characters */
    .struct XTI_nchars + 8    
XTI_delta:    /* delta between strings */
    .struct XTI_delta + 8
XTI_font:    /* Font to print it in, None don't change */
    .struct XTI_font + 8        
XTI_fin:
/**********************************************/
/* structure    XGCValues                  */
    .struct  0
XGC_function:                 /* logical operation */
    .struct XGC_function + 8
XGC_plane_mask:             /* plane mask */
    .struct XGC_plane_mask + 8
XGC_foreground:             /* foreground pixel */
    .struct XGC_foreground + 8
XGC_background:             /* background pixel */
    .struct XGC_background + 8
XGC_line_width:             /* line width */
    .struct XGC_line_width + 8
XGC_line_style:             /* LineSolid, LineOnOffDash, LineDoubleDash */
    .struct XGC_line_style + 8
XGC_cap_style:                 /* CapNotLast, CapButt,CapRound, CapProjecting */
    .struct XGC_cap_style + 8
XGC_join_style:             /* JoinMiter, JoinRound, JoinBevel */
    .struct XGC_join_style + 8
XGC_fill_style:             /* FillSolid, FillTiled,FillStippled, FillOpaeueStippled */
    .struct XGC_fill_style + 8
XGC_fill_rule:                 /* EvenOddRule, WindingRule */
    .struct XGC_fill_rule + 8
XGC_arc_mode:                 /* ArcChord, ArcPieSlice */
    .struct XGC_arc_mode + 8
XGC_tile:                   /* tile pixmap for tiling operations */
    .struct XGC_tile + 8
XGC_stipple: .word    0    /* stipple 1 plane pixmap for stipping */
    .struct XGC_stipple + 8
XGC_ts_x_origin:             /* offset for tile or stipple operations */
    .struct XGC_ts_x_origin + 8
XGC_ts_y_origin: 
    .struct XGC_ts_y_origin + 8
XGC_font:                         /* default text font for text operations */
    .struct XGC_font + 8
XGC_subwindow_mode:             /* ClipByChildren, IncludeInferiors */
    .struct XGC_subwindow_mode + 8
XGC_graphics_exposures:             /* boolean, should exposures be generated */
    .struct XGC_graphics_exposures + 8
XGC_clip_x_origin:                 /* origin for clipping */
    .struct XGC_clip_x_origin + 8
XGC_clip_y_origin:         
    .struct XGC_clip_y_origin + 8
XGC_clip_mask:                 /* bitmap clipping; other calls for rects */
    .struct XGC_clip_mask + 8
XGC_dash_offset:             /* patterned/dashed line information */
    .struct XGC_dash_offset + 8
XGC_dashes: 
    .struct XGC_dashes + 8
XGC_fin:
    
 /**********************************************/
/* evenement Xconfigure */
    .struct  0
XConfigureEvent_type:    
    .struct XConfigureEvent_type + 8
XConfigureEvent_serial:
    .struct XConfigureEvent_serial + 8 /* # of last request processed by server */
XConfigureEvent_send_event:
    .struct XConfigureEvent_send_event  + 8 /* true if this came from a SendEvent request */
XConfigureEvent_display:
    .struct XConfigureEvent_display  + 8    /* Display the event was read from */
XConfigureEvent_event:
    .struct XConfigureEvent_event  + 8    
XConfigureEvent_window:
    .struct XConfigureEvent_window  + 8    
XConfigureEvent_x:
    .struct XConfigureEvent_x  + 8
XConfigureEvent_y:
    .struct XConfigureEvent_y  + 8    
XConfigureEvent_width:
    .struct XConfigureEvent_width  + 8    
XConfigureEvent_height:
    .struct XConfigureEvent_height  + 8
XConfigureEvent_border_width:
    .struct XConfigureEvent_border_width  + 8
XConfigureEvent_above:
    .struct XConfigureEvent_above  + 8
XConfigureEvent_override_redirect:
    .struct XConfigureEvent_override_redirect  + 8
/***************************************************/
/* structure XButtonEvent    */
    .struct  0
XBE_type:              
    .struct XBE_type + 8  /* TODO A REVOIR erreur ligne suivante */               
XBE_serial:             /* No  last request processed  server */ 
    .struct XBE_serial + 8 
XBE_send_event:              /* true if this came from a SendEvent request */ 
    .struct XBE_send_event + 8     
XBE_display:              /* Display the event was read from */  
    .struct XBE_display + 8      
XBE_window:                 /* "event" window it is reported relative to */
    .struct XBE_window + 8  
XBE_root:                 /* root window that the event occurred on */
    .struct XBE_root + 8  
XBE_subwindow:              /* child window */ 
    .struct XBE_subwindow + 8  
XBE_time:              /* milliseconds */   
    .struct XBE_time + 8      
XBE_x:                 /* pointer x, y coordinates in event window */
    .struct XBE_x + 8
XBE_y:              
    .struct XBE_y + 8
XBE_x_root:              /* coordinates relative to root */
    .struct XBE_x_root + 8
XBE_y_root:              
    .struct XBE_y_root + 8    
XBE_state:              /* key or button mask */
    .struct XBE_state + 8                                    
XBE_button:              /* detail */
    .struct XBE_button + 8    
XBE_same_screen:         /* same screen flag */    
    .struct XBE_same_screen + 8        
XBE_fin:
/***************************************************/
/* structure XMotionEvent */    
    .struct  0
XMotion_type:              
    .struct XMotion_type + 8
XMotion_serial:              /* # of last request processed by server */
    .struct XMotion_serial + 8    
XMotion_send_event:              /* true if this came from a SendEvent request */
    .struct XMotion_send_event + 8
XMotion_display:              /* Display the event was read from */
    .struct XMotion_display + 8
XMotion_window:               /* "event" window reported relative to */
    .struct XMotion_window + 8
XMotion_root:               /* root window that the event occurred on */
    .struct XMotion_root + 8
XMotion_subwindow:              /* child window */
    .struct XMotion_subwindow + 8
XMotion_time:              /* milliseconds */
    .struct XMotion_time + 8
XMotion_x:              /* pointer x, y coordinates in event window */
    .struct XMotion_x + 8    
XMotion_y:              
    .struct XMotion_y + 8
XMotion_x_root:              /* coordinates relative to root */
    .struct XMotion_x_root + 8    
XMotion_y_root:              
    .struct XMotion_y_root + 8    
XMotion_state:              /* key or button mask */
    .struct XMotion_state + 8
XMotion_hint:              /* detail */
    .struct XMotion_hint + 8
XMotion_same_screen:              /* same screen flag */
    .struct XMotion_same_screen + 8    
XMotion_fin:    

/***************************************************/
/* structure XClientMessageEvent */    
    .struct  0
XClient_type:
    .struct XClient_type + 8
XClient_serial:            /* # of last request processed by server */
    .struct XClient_serial + 8
XClient_send_event:        /* true if this came from a SendEvent request */
    .struct XClient_send_event + 8
XClient_display:        /* Display the event was read from */
    .struct XClient_display + 8
XClient_window:
    .struct XClient_window + 8
XClient_message_type:
    .struct XClient_message_type + 8
XClient_format:
    .struct XClient_format + 8
XClient_data:        /* datas */
    .struct XClient_data + 8
XClient_fin:


/***************************************************/
/* structure XAnyEvent */    
    .struct  0
XAny_type:              
    .struct XAny_type + 8
XAny_serial:              
    .struct XAny_serial + 8   /* # of last request processed by server */
XAny_send_event:              
    .struct XAny_send_event + 8    /* true if this came from a SendEvent request */
XAny_display:              
    .struct XAny_display + 8  /* Display the event was read from */
XAny_window:              
    .struct XAny_window + 8     /* window on which event was requested in event mask */
Xany_fin:

/***************************************************/
/* structure XSetWindowAttributes */
    .struct  0
Att_background_pixmap:              /* background or None or ParentRelative */
    .struct Att_background_pixmap + 8
Att_background_pixel:              /* background pixel */
    .struct Att_background_pixel + 8    
Att_border_pixmap:              /* border of the window */
    .struct Att_border_pixmap + 8    
Att_border_pixel:              /* border pixel */
    .struct Att_border_pixel + 8    
Att_bit_gravity:              /* one of bit gravity values */
    .struct Att_bit_gravity + 8 
Att_win_gravity:              /* one of the window gravity values */
    .struct Att_win_gravity + 8     
Att_backing_store:            /* NotUseful, WhenMapped, Always */
    .struct Att_backing_store + 8      
Att_backing_planes:            /* planes to be preseved if possible */
    .struct Att_backing_planes + 8  
Att_backing_pixel:            /* value to use in restoring planes */
    .struct Att_backing_pixel + 8     
Att_save_under:            /* should bits under be saved? (popups) */
    .struct Att_save_under + 8   
Att_event_mask:            /* set of events that should be saved */
    .struct Att_event_mask + 8       
Att_do_not_propagate_mask:            /* set of events that should be saved */
    .struct Att_do_not_propagate_mask + 8     
Att_override_redirect:            /* boolean value for override-redirect */
    .struct Att_override_redirect + 8        
Att_colormap:            /* color map to be associated with window */
    .struct Att_colormap + 8     
Att_cursor:            
    .struct Att_cursor + 8      
Att_fin:        
/*******************FIN*****************************/    
/* structure de type   XWMHints   */
    .struct  0
Hints_flags:              /* marks which fields in this structure are defined */
    .struct Hints_flags + 8
Hints_input:              /* does this application rely on the window manager to
                   get keyboard input? */
    .struct Hints_input + 8    
Hints_initial_state:             
    .struct Hints_initial_state + 8    
Hints_icon_pixmap:             /* pixmap to be used as icon */
    .struct Hints_icon_pixmap + 8    
Hints_icon_window:             /* window to be used as icon */
    .struct Hints_icon_window + 8    
Hints_icon_x:             /* initial position of icon */
    .struct Hints_icon_x + 8    
Hints_icon_y:             
    .struct Hints_icon_y + 8    
Hints_icon_mask:                 /* pixmap to be used as mask for icon_pixmap */
    .struct Hints_icon_mask + 8        
Hints_window_group:             /* id of related window group */
    .struct Hints_window_group + 8    
Hints_fin:
/*******************FIN*****************************/    
/* structure de type   XSizeHints   */
    .struct  0
XSize_flags:              /* marks which fields in this structure are defined */
    .struct XSize_flags + 8
XSize_x:              
    .struct XSize_x + 8
XSize_y:              
    .struct XSize_y + 8
XSize_width:              
    .struct XSize_width + 8
XSize_height:              
    .struct XSize_height + 8
XSize_min_width:              
    .struct XSize_min_width + 8    
XSize_min_height:              
    .struct XSize_min_height + 8    
XSize_max_width:              
    .struct XSize_max_width + 8    
XSize_max_height:              
    .struct XSize_min_height + 8        
XSize_width_inc:              
    .struct XSize_width_inc + 8    
XSize_height_inc:              
    .struct XSize_height_inc + 8    
XSize_min_aspect_x:              
    .struct XSize_min_aspect_x + 8    
XSize_min_aspect_y:              
    .struct XSize_min_aspect_y + 8    
XSize_max_aspect_x:              
    .struct XSize_max_aspect_x + 8    
XSize_max_aspect_y:              
    .struct XSize_max_aspect_y + 8        
XSize_base_width:              
    .struct XSize_base_width + 8    
XSize_base_height:              
    .struct XSize_base_height + 8
XSize_win_gravity:              
    .struct XSize_win_gravity + 8    
XSize_fin:    
/* structure de type   XColor   */
    .struct  0
XColor_pixel:	          	/* pixel value */
    .struct XColor_pixel + 8
XColor_red:	          	/* pixel value   TODO A VERIFIER */
    .struct XColor_red + 8
XColor_green:	          	/* pixel value */
    .struct XColor_green + 8
XColor_blue:	          	/* pixel value */
    .struct XColor_blue + 8	
XColor_flags:	          	/* DoRed, DoGreen, DoBlue */	
    .struct XColor_flags + 8	
XColor_pad:	          	/* pixel value */
    .struct XColor_pad + 8
XColor_fin:
/*******************FIN*****************************/    
/* structure de type   fichier   */
    .struct  0
file_name:              /* nom */
    .struct file_name + 256
file_datas:              /* donnees lues */
    .struct file_datas + 8
file_size:              /* taille */
    .struct file_size + 8
file_offset:              /* offset */
    .struct file_offset + 8
file_fin:


