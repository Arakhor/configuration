{ lib }:
let
  inherit (lib) types;
in
{
  nushellValue =
    let
      valueType = types.nullOr (
        types.oneOf [
          (lib.mkOptionType {
            name = "nushell";
            description = "Nushell inline value";
            descriptionClass = "name";
            check = lib.isType "nushell-inline";
          })
          types.bool
          types.int
          types.float
          types.str
          types.path
          (
            types.attrsOf valueType
            // {
              description = "attribute set of Nushell values";
              descriptionClass = "name";
            }
          )
          (
            types.listOf valueType
            // {
              description = "list of Nushell values";
              descriptionClass = "name";
            }
          )
        ]
      );
    in
    valueType;
}
