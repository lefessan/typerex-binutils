(**************************************************************************)
(*                                                                        *)
(*  Copyright 2012 OCamlPro                                               *)
(*                                                                        *)
(*  All rights reserved.  This file is distributed under the terms of     *)
(*  the GNU Public License version 3.0.                                   *)
(*                                                                        *)
(*  TypeRex is distributed in the hope that it will be useful,            *)
(*  but WITHOUT ANY WARRANTY; without even the implied warranty of        *)
(*  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the         *)
(*  GNU General Public License for more details.                          *)
(*                                                                        *)
(**************************************************************************)
(***********************************************************************)
(*                                                                     *)
(*           Written by Fabrice LE FESSANT, OcamlPro                  *)
(*                                                                     *)
(*                   for Lexify SAS                                    *)
(*                     (2009/12)                                       *)
(***********************************************************************)

open StringCompat
open BinobjFile
open IntelasmTypes









let new_segment () = {
  seg_labels = StringMap.empty;
  seg_pos = 0;
  seg_instrs = Queue.create ();
}

let clear_segment s =
  s.seg_labels <- StringMap.empty;
  s.seg_pos <- 0;
  s.seg_instrs <- Queue.create ()

let emit seg ins args =
  Queue.add {
    pos = seg.seg_pos;
    instr = ins;
    args = args}  seg.seg_instrs;
  match ins with
    NewLabel lbl ->
      seg.seg_labels <- StringMap.add lbl seg.seg_pos seg.seg_labels
  | Global _ -> ()
  | Align (_, 16) -> (* 16-bytes align can grow to 15 bytes *)
    seg.seg_pos <- seg.seg_pos + 2
  | _ -> seg.seg_pos <- seg.seg_pos + 1


let label_name i = Printf.sprintf "L%i" i

let emit_label_abs n = LabelAbs (label_name  n,0L)
let emit_label_rel n = LabelRel (label_name  n,0L)
let emit_label_rip n = Mem (RIP, 1, BaseSymbol (label_name n), 0)
let emit_label_abs_with_offset s n = LabelAbs (label_name s,n)
let emit_label_rel_with_offset s n = LabelRel (label_name s,n)



let symbol_name s =
  let b = Buffer.create (1 + String.length s) in
    (* Buffer.add_char b '_'; *)
  String.iter
    (function
    | ('A'..'Z' | 'a'..'z' | '0'..'9' | '_') as c -> Buffer.add_char b c
    | c -> Printf.bprintf b "$%02x" (Char.code c)
    )
    s;
  Buffer.contents b

let emit_global_label seg lbl =
  let lbl = symbol_name lbl in
  emit seg (Global lbl) [];
  emit seg (NewLabel lbl) []

let emit_symbol_abs_with_offset s n = LabelAbs (symbol_name s,n)
let emit_symbol_rel_with_offset s n = LabelRel (symbol_name s,n)
let emit_symbol_abs s = LabelAbs (symbol_name s,0L)
let emit_symbol_rel s = LabelRel (symbol_name s,0L)
let emit_symbol_rip s = Mem (RIP, 1, BaseSymbol (symbol_name s), 0)


let emit_int n = Constant64 (Int64.of_int n)
let emit_int32 n = Constant64 (Int64.of_int32 n)
let emit_int64 n = Constant64 n
let emit_nativeint n = Constant64 (Int64.of_nativeint n)

let def_label seg l =
  emit seg (NewLabel (label_name l)) []
