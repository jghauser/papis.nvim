{
  name,
  self,
}:
final: prev:
let
  papis-nvim-luaPackage-override = luaself: luaprev: {
    papis-nvim = luaself.callPackage (
      {
        buildLuarocksPackage,
        lua,
        luaOlder,
        nui-nvim,
        sqlite,
      }:
      buildLuarocksPackage {
        pname = name;
        version = "scm-1";
        knownRockspec = "${self}/${name}-scm-1.rockspec";
        disabled = luaOlder "5.1";
        propagatedBuildInputs = [
          nui-nvim
          sqlite
        ];
        src = self;
      }
    ) { };
  };

  lua5_1 = prev.lua5_1.override {
    packageOverrides = papis-nvim-luaPackage-override;
  };
  lua51Packages = prev.lua51Packages // final.lua5_1.pkgs;
  luajit = prev.luajit.override {
    packageOverrides = papis-nvim-luaPackage-override;
  };
  luajitPackages = prev.luajitPackages // final.luajit.pkgs;
in
{
  inherit
    lua5_1
    lua51Packages
    luajit
    luajitPackages
    ;

  vimPlugins = prev.vimPlugins // {
    papis-nvim = final.neovimUtils.buildNeovimPlugin {
      luaAttr = luajitPackages.papis-nvim;
    };
  };
}
