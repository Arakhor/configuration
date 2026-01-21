self: lib:
let
    inherit (lib)
        mkEnableOption
        mkOption
        mkDefault
        mkForce
        mapAttrsRecursive
        ;

    inherit (builtins) mapAttrs;
in
rec {
    mkOpt =
        type: default: description:
        mkOption { inherit type default description; };
    mkOpt' = type: default: mkOpt type default null;

    mkEnabledOption = desc: mkEnableOption desc // { default = true; };

    mkDefaultAttrs = attrs: mapAttrs (_: v: mkDefault v) attrs;
    mkDefaultAttrsRecursive = attrs: mapAttrsRecursive (_: v: mkDefault v) attrs;

    mkForceAttrs = attrs: mapAttrs (_: v: mkForce v) attrs;
    mkForceAttrsRecursive = attrs: mapAttrsRecursive (_: v: mkForce v) attrs;
}
