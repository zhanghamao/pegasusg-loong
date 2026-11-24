#pragma once

#include <cstdint>
#include <string>
#include <vector>

enum class GbaCore {
  Mgba = 0,
  Gpsp = 1,
  Vbam = 2,
  VbaNext = 3,
};

inline const char *GbaCoreStorageName(GbaCore core) {
  switch (core) {
    case GbaCore::Gpsp: return "gpsp";
    case GbaCore::Vbam: return "vbam";
    case GbaCore::VbaNext: return "vba_next";
    default: return "mgba";
  }
}

inline GbaCore GbaCoreFromStorageName(const std::string &name) {
  if (name == "gpsp") return GbaCore::Gpsp;
  if (name == "vbam") return GbaCore::Vbam;
  if (name == "vba_next") return GbaCore::VbaNext;
  return GbaCore::Mgba;
}

// Non-GBA platforms supported on LoongOS (mini-dragon) RetroArch cores.
inline bool IsExtendedPlatform(const std::string &platform) {
  return platform != "GBA" && !platform.empty();
}

inline const char *PlatformDefaultCore(const std::string &platform) {
  if (platform == "FC") return "fceumm";
  if (platform == "SFC") return "snes9x";
  if (platform == "MD") return "genesis_plus_gx";
  if (platform == "SMS") return "genesis_plus_gx";
  if (platform == "GG") return "genesis_plus_gx";
  if (platform == "GB") return "gambatte";
  if (platform == "GBC") return "gambatte";
  if (platform == "PCE") return "mednafen_pce";
  if (platform == "PSX") return "pcsx_rearmed";
  if (platform == "WS") return "mednafen_wswan";
  if (platform == "NGP") return "mednafen_ngp";
  if (platform == "ARC" || platform == "街机FBNEO") return "fbneo";
  if (platform == "街机MAME") return "mame2003_plus";
  return "mgba";
}

struct GbaGame {
  std::string id;
  std::string title;
  std::string developer;
  std::string description;
  std::string sort_key;
  std::string rom_path;
  std::vector<std::string> alternate_roms;
  std::string cover_path;
  std::string logo_path;
  std::string video_path;
  std::string metadata_path;
  std::string platform;        // "GBA", "FC", "SFC", "MD", "SMS", "GG", "GB", "PCE", ...
  std::string metadata_core;   // raw core hint from metadata (any platform)
  bool is_mod = false;
  bool is_rumble = false;
  bool favorite = false;
  std::uint64_t favorite_order = 0;
  std::uint64_t recent_order = 0;
  GbaCore default_core = GbaCore::Mgba;
  GbaCore core = GbaCore::Mgba;
  bool core_overridden = false;
};

inline std::string GbaLaunchCoreName(const GbaGame &game) {
  // Metadata core hint wins (works for every platform).
  if (!game.metadata_core.empty()) return game.metadata_core;
  // Non-GBA platforms use their platform default core.
  if (IsExtendedPlatform(game.platform)) return PlatformDefaultCore(game.platform);
  switch (game.core) {
    case GbaCore::Gpsp: return game.is_rumble ? "gpsp_rumble" : "gpsp";
    case GbaCore::Vbam: return "vbam";
    case GbaCore::VbaNext: return "vba_next";
    default: return "mgba";
  }
}

struct PegasusScanReport {
  std::vector<GbaGame> games;
  int metadata_files = 0;
  int parsed_entries = 0;
  int missing_rom_entries = 0;
  int duplicate_rom_entries = 0;
  int unreferenced_roms = 0;
  std::vector<std::string> warnings;
};
