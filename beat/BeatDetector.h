#ifndef BEATDETECTOR_H
#define BEATDETECTOR_H


#ifdef __cplusplus
#include <iostream>
#include <stdio.h>
#include <memory>
class BeatDetector
{
public:
  BeatDetector(const float* ptr, uint32_t length);

  float* get_energie1024();
  float* get_energie44100();
  bool* get_energie_peak();
  float* get_conv();
  float* get_beat();
  int get_tempo();

private:

  uint32_t length;    // en PCM

  std::unique_ptr<float[]> energie1024; // energie of 1024 samples computed every 1024 pcm
  std::unique_ptr<float[]> energie44100; // energie of 44100 samples computed every 1024 pcm
  std::unique_ptr<bool[]> energie_peak; // les beat probables
  std::unique_ptr<float[]> conv; // la convolution avec un train d'impulsions
  std::unique_ptr<float[]> beat; // la beat line
  int tempo; // le tempo en BPMs

  void audio_process(const float* data);
  float energie(const float* data, int offset, int window); // calcul l'energie du signal a une position et sur une largeur donnée
  void normalize(float* signal, int size, float max_val); // reajuste les valeurs d'un signal à la valeur max souhaitée
  int search_max(float* signal, int pos, int fenetre_half_size); // recherche d'un max dans les parages de pos
};

extern "C" {
#endif // __cplusplus

typedef struct BeatDetectorRef {
  void* ptr;
} BeatDetectorRef;

void BeatDetectorNew(const float* data, unsigned int length, BeatDetectorRef* ref);
float* BeatDetectorGetBeat(BeatDetectorRef ref);
int BeatDetectorGetTempo(BeatDetectorRef ref);
void BeatDetectorDelete(BeatDetectorRef ref);

#ifdef __cplusplus
}
#endif // __cplusplus


#endif // BEATDETECTOR_H
