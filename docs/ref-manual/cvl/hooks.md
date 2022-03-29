Hooks
=====

Hooks are used to attach CVL code to certain low-level operations, such as
loads and stores to specific storage slots.

```{todo}
This documentation is incomplete.  See
[the old documentation](/docs/confluence/anatomy/hooks)
for partial information.
```

```{contents}
```

Syntax
------

```
hook ::= store_hook | load_hook

load_hook ::= "hook" "Sload"
              cvl_type id
              slot_pattern
              "STORAGE" block

store_hook ::= "hook" "Sstore"
               slot_pattern
               cvl_type id [ "(" cvl_type id ")" ]
               "STORAGE" block

TODO: the following needs condensing and explaining
      it is a description of slot_pattern (from cvl.cup)

/**
   (slot 2) -> 3rd storage slot
   (slot 0, offset 8) -> 1st storage slot, variable packed at 8 bytes
                        [ ... 8 bytes ... (* match! *) ... ? bytes ... | ... slot 2 ... | ... ]
   (slot 1)[uint key] -> an element of the mapping found at storage slot 1, whose key will be bound to the variable 'key'
   (slot 1).(offset 64) -> in the struct located in the 2nd slot, the member of the struct located 64 bytes (2 evm words)
                            from the start of the struct
                            [ ... 32 bytes ... { ... 64 bytes ... (* match! *) ... } ... ]
*/

static_slot_part ::= ID:id                                                                      {: RESULT = new StaticSlotPatternNamed(id); :}
                 |   LP ID:keyword NUMBER:number RP                                             {: RESULT = new StaticSlotPatternNumber(keyword, new NumberExp(number)); :}
                 |   LP ID:slot_keyword NUMBER:slot COMMA ID:offset_keyword NUMBER:offset RP    {: RESULT = new StaticSlotPatternTwoNumbers(slot_keyword, new NumberExp(slot), offset_keyword, new NumberExp(offset)); :}
;

static_slot_pattern ::= static_slot_part:part {: StaticSlotPattern p = new StaticSlotPattern(theFilename, partxleft); p.add(part); RESULT = p; :}
                    |   static_slot_pattern:pattern DOT static_slot_part:part {: pattern.add(part); RESULT = pattern; :}
;

slot_pattern_break_dots ::= static_slot_pattern:sp LSQB ID:key_or_index single_param:p RSQB
                        {: if (key_or_index.equals("KEY")) {
                                RESULT = new MapAccessSlotPattern(sp, p);
                           } else if (key_or_index.equals("INDEX")) {
                                RESULT = new ArrayAccessSlotPattern(sp, p);
                           } else {
                                report_fatal_error("A mapping or array access pattern must use either the keyword 'key' or 'index' respectively", cur_token);
                           }
                        :}
;

slot_pattern_nested ::= slot_pattern_break_dots:sp {: RESULT = sp; :}
             |   slot_pattern_nested:sp LSQB ID:key_or_index single_param:p RSQB
                        {: if (key_or_index.equals("KEY")) {
                                RESULT = new MapAccessSlotPattern(sp, p);
                           } else if (key_or_index.equals("INDEX")) {
                                RESULT = new ArrayAccessSlotPattern(sp, p);
                           } else {
                                report_fatal_error("A mapping or array access pattern must use either the keyword 'key' or 'index' respectively", cur_token);
                           }
                        :}
             |   slot_pattern_nested:sp DOT ID:field {: RESULT = new FieldAccessSlotPattern(sp, field); :}
             |   slot_pattern_nested:sp DOT LP ID:offset_keyword NUMBER:offset RP
                        {: if (!offset_keyword.equals("offset")) {
                                report_fatal_error("A struct access pattern must use the keyword 'offset'", cur_token);
                           } else {
                                RESULT = new StructAccessSlotPattern(sp, new NumberExp(offset));
                           }
                        :}
;

slot_pattern ::= slot_pattern_nested:sp {: RESULT = sp; :}
             |   static_slot_pattern:sp {: RESULT = sp; :}
             ;

```
