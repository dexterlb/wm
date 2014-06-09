echo '
partial alphanumeric_keys 
xkb_symbols "dvorak_phonetic" {
  name[Group1]= "Dvorak Bulgarian (traditional phonetic)";
  
  key <TLDE> {   [ Cyrillic_che,      Cyrillic_CHE        ]    };
  key <AE01> {   [ 1,                 exclam              ]    };
  key <AE02> {   [ 2,                 at                  ]    };
  key <AE03> {   [ 3,                 numerosign          ]    };
  key <AE04> {   [ 4,                 dollar,
		   EuroSign,          EuroSign            ]    };
  key <AE05> {   [ 5,                 percent             ]    };
  key <AE06> {   [ 6,                 EuroSign            ]    };
  key <AE07> {   [ 7,                 section             ]    };
  key <AE08> {   [ 8,                 asterisk            ]    };
  key <AE09> {   [ 9,                 parenleft,
		   bracketleft,       U2329               ]    };
  key <AE10> {   [ 0,                 parenright,
		   bracketright,      U232A               ]    };
  key <AE11> {   [ Cyrillic_sha,      Cyrillic_SHA        ]    };
  key <AE12> {   [ Cyrillic_shcha,    Cyrillic_SHCHA      ]    };

  key <AC11> {   [ minus,             endash,
		   U2011,             U2011               ]    };
  key <AC02> {   [ Cyrillic_o,        Cyrillic_O          ]    };
  key <AC03> {   [ Cyrillic_ie,       Cyrillic_IE,
		   Cyrillic_e,        Cyrillic_E          ]    };
  key <AC04> {   [ Cyrillic_u,        Cyrillic_U          ]    };
  key <AC05> {   [ Cyrillic_i,        Cyrillic_I,
		   U045D,             U040D               ]    };
  key <AC06> {   [ Cyrillic_de,       Cyrillic_DE         ]    };
  key <AC08> {   [ Cyrillic_te,       Cyrillic_TE,
		   trademark,         trademark           ]    };
  key <AC09> {   [ Cyrillic_en,       Cyrillic_EN         ]    };
  key <AC01> {   [ Cyrillic_a,        Cyrillic_A          ]    };
  key <AC10> {   [ Cyrillic_es,       Cyrillic_ES,
		   copyright,         copyright           ]    };
  key <AC07> {   [ Cyrillic_ha,       Cyrillic_HA         ]    };
  
  key <AB07> {   [ Cyrillic_em,       Cyrillic_EM         ]    };
  key <AB02> {   [ Cyrillic_ya,       Cyrillic_YA,
		   U0463,             U0462               ]    };
  key <AB03> {   [ Cyrillic_shorti,   Cyrillic_SHORTI,
		   U046D,             U046C               ]    };
  key <AB04> {   [ Cyrillic_ka,       Cyrillic_KA         ]    };
  key <AB09> {   [ Cyrillic_zhe,      Cyrillic_ZHE        ]    };
  key <AB06> {   [ Cyrillic_be,       Cyrillic_BE         ]    };
  key <AB10> {   [ Cyrillic_ze,       Cyrillic_ZE         ]    };
  key <AB05> {   [ Cyrillic_softsign, U045D,
		   Cyrillic_yeru,     Cyrillic_YERU       ]    };
  key <AB01> {   [ semicolon,         colon,
		   ellipsis,          ellipsis            ]    };

  key <AB08> {   [ Cyrillic_ve,       Cyrillic_VE         ]    };
  key <AD09> {   [ Cyrillic_er,       Cyrillic_ER,
		   registered,        registered          ]    };
  key <AD05> {   [ Cyrillic_hardsign, Cyrillic_HARDSIGN,
		   U046B,             U046A               ]    };
  key <AD04> {   [ Cyrillic_pe,       Cyrillic_PE         ]    };
  
  
  key <AD06> {   [ Cyrillic_ef,       Cyrillic_EF         ]    };
  key <AD07> {   [ Cyrillic_ghe,      Cyrillic_GHE        ]    };
  key <AD12> {   [ equal,             plus,
		   emdash,            dagger              ]    };
  key <AD10> {   [ Cyrillic_el,       Cyrillic_EL         ]    };
  key <AD01> {   [ apostrophe,        quotedbl,
		   rightsinglequotemark, leftsinglequotemark ] };
  key <BKSL> {   [ Cyrillic_yu,       Cyrillic_YU         ]    };
  
  
  key <LSGT> {   [ U045D,             U040D               ]    };
  key <AD08> {   [ Cyrillic_tse,      Cyrillic_TSE,
		   copyright,         copyright           ]    };
  key <AD02> {   [ comma,             doublelowquotemark,
		   guillemotleft,     guillemotleft       ]    };
  key <AD03> {   [ period,            leftdoublequotemark,
		   guillemotright,    guillemotright      ]    };
  key <AD11> {   [ slash,             question,
		   U0300,             U0301               ]    };


  key <SPCE> {   [ space,             space,
		   nobreakspace,      nobreakspace        ]    };


  key <KPDL> {   type[Group1] = "KEYPAD",
                 [ KP_Delete,           KP_Separator         ]    };

};
' >> /usr/share/X11/xkb/symbols/bg
