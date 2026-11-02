#include <QImage>
#include <cstdio>
#include <vector>

extern "C" {
#include <mgba/core/core.h>
#include <mgba/core/log.h>
}

static void quietLog(mLogger *, int, mLogLevel, const char *, va_list) {}
static mLogger quiet = { quietLog, nullptr }         ;

int main (int argc, char *argv[]) {
  mLogSetDefaultLogger(&quiet)                       ;
  if (argc < 2) {
    std::fprintf(stderr, "headless_test <rom.gba>\n");
    return 1                                         ;
  }

  mCore *core = mCoreFind(argv[1])                   ;

  if (!core) {
    std::fprintf(stderr, "no core for this file\n")  ;
    return 1                                         ;
  }
  core->init(core)                                   ;
  mCoreInitConfig(core, "jankk")                     ;

  unsigned w = 0, h = 0                              ;
  core->desiredVideoDimensions(core, &w, &h)         ;
  std::printf("video size: %ux%u\n", w, h)           ;

  std::vector<uint32_t> buf(w * h)                   ;
  core->setVideoBuffer(core,
        reinterpret_cast<color_t *>(buf.data()), w)  ;

  if (!mCoreLoadFile(core, argv[1])) {
    std::fprintf(stderr, "failed to load rom\n")     ;
    core->deinit(core)                               ;
    return 1                                         ;
  }
  core->reset(core)                                  ;

  for (int i = 0 ; i < 600; ++i) 
    core->runFrame(core)                             ;

  QImage img(reinterpret_cast<uchar *>(buf.data()),
      w, h, w * 4, QImage::Format_RGBX8888)          ;
  img.save("frame.png")                              ;
  std::printf("ran 600 frames, wrote frame.png\n")   ;

  core->deinit(core)                                 ;
  
  return 0                                           ;
}

