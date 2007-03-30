-------------------------------------------------------------------------------
-- Le langage VHDL : du langage au circuit, du circuit au langage.
-- Copyright (C) Jacques Weber, S�bastien Moutault et Maurice Meaudre, 2006.
--
-- Ce programme est libre, vous pouvez le redistribuer et/ou le modifier selon
-- les termes de la Licence Publique G�n�rale GNU publi�e par la Free Software
-- Foundation (version 2 ou bien toute autre version ult�rieure choisie par
-- vous).
--
-- Ce programme est distribu� car potentiellement utile, mais SANS AUCUNE
-- GARANTIE, ni explicite ni implicite, y compris les garanties de
-- commercialisation ou d'adaptation dans un but sp�cifique. Reportez-vous �
-- la Licence Publique G�n�rale GNU pour plus de d�tails.
--
-- Vous devez avoir re�u une copie de la Licence Publique G�n�rale GNU en m�me
-- temps que ce programme ; si ce n'est pas le cas, �crivez � la Free Software
-- Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307,
-- �tats-Unis.
--
-- jacques.weber@lelangagevhdl.net
-- sebastien.moutautl@lelangagevhdl.net
-------------------------------------------------------------------------------
-- Projet     :
-- Design     :
-- Fichier    : rompkg.vhd
-- Module     : PACKAGE rompkg
-- Descript.  :
-- Auteur     : J.Weber
-- Date       : 03/03/07
-- Version    : 1.0
-- Depend.    :
-- Simulation : ModelSim 6.0d
-- Synth�se   :
-- Remarques  :
--
--
-------------------------------------------------------------------------------
-- Date     | R�v | Description
-- 01/08/06 | 1.0 | Premi�re version stable utilis�e pour le livre.
-- 03/03/07 |     | Pas de modifications du design.
--          |     | Preparation pour la mise en ligne.
--          |     |
--          |     |
-------------------------------------------------------------------------------


LIBRARY IEEE ;
USE IEEE.STD_LOGIC_1164.ALL ;

PACKAGE rompkg IS
   CONSTANT ad_nb_bits : INTEGER := 3 ; -- e
   CONSTANT size: INTEGER := 2**ad_nb_bits ; -- 8 bytes
   SUBTYPE byte IS STD_LOGIC_VECTOR(7 DOWNTO 0) ;
   TYPE rom_tbl IS ARRAY(NATURAL RANGE <>) OF byte ;
END PACKAGE rompkg ;


