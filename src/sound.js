import { Transport, Compressor, Loop, Player, Reverb, Volume, PanVol, start, loaded } from 'tone'

import whistle_8_T7 from '../public/sound/whistle/whistle_8_T7.mp3'
import whistle_4_T3 from '../public/sound/whistle/whistle_4_T3.mp3'
import whistle_7_T6 from '../public/sound/whistle/whistle_7_T6.mp3'
import whistle_12_T11 from '../public/sound/whistle/whistle_12_T11.mp3'
import whistle_8_T7_B from '../public/sound/whistle/whistle_8_T7_B.mp3'

import wii_2_T1 from '../public/sound/wii/wii_2_T1.mp3'
import wii_4_T3 from '../public/sound/wii/wii_4_T3.mp3'
import wii_8_T7 from '../public/sound/wii/wii_8_T7.mp3'
import wii_10_T9 from '../public/sound/wii/wii_10_T9.mp3'
import wii_12_T11 from '../public/sound/wii/wii_12_T11.mp3'
import wii_T5 from '../public/sound/wii/wii_T5.mp3'

import ipod_2_T1 from '../public/sound/ipod/ipod_2_T1.mp3'
import ipod_5_T4 from '../public/sound/ipod/ipod_5_T4.mp3'
import ipod_7_T6 from '../public/sound/ipod/ipod_7_T6.mp3'
import ipod_8_T7 from '../public/sound/ipod/ipod_8_T7.mp3'
import ipod_14_FX from '../public/sound/ipod/ipod_14_FX.mp3'
import ipod_15_Delay_Reverb from '../public/sound/ipod/ipod_15_Delay_Reverb.mp3'
import ipod_hiss from '../public/sound/ipod/ipod_hiss.mp3'

const SONGS = {
  whistle: {
    bpm: 70,
    parts: [[
      // each part consists of a set of tracks
      // type Track: [sample, probability, introProbability?]
      [whistle_8_T7, 1, 0],
      [whistle_4_T3, 0.9, 1],
      [whistle_7_T6, 0.7, 1],
      [whistle_12_T11, 0.7, 0],
    ], [
      [whistle_8_T7_B, 1, 0],
      [whistle_4_T3, 0.7, 1],
      [whistle_7_T6, 0.7, 1],
      [whistle_12_T11, 0.7, 0],
    ]],
  },
  wii: {
    bpm: 70,
    parts: [[
      [wii_2_T1, 1, 0],
      [wii_4_T3, 0.9, 1],
      [whistle_7_T6, 0.7, 1],
      [wii_12_T11, 0.7, 0],
      [wii_10_T9, 0.9, 0],
      [wii_T5, 0.2, 1],
    ], [
      [wii_2_T1, 1, 0],
      [wii_4_T3, 0.9, 0],
      [wii_8_T7, 1, 1],
      [whistle_7_T6, 0.7, 1],
      [wii_12_T11, 0.8, 0],
      [wii_10_T9, 0.7, 0],
    ]],
  },
  ipod: {
    bpm: 113,
    parts: [[
      [ipod_2_T1, 0.9, 0],
      [ipod_5_T4, 0.9, 1],
      [ipod_7_T6, 0.7, 1],
      [ipod_8_T7, 0.7, 0],
      [ipod_14_FX, 0.5, 0],
      [ipod_15_Delay_Reverb, 1, 0],
      [ipod_hiss, 0.5, 0],
    ]],
  }
}

const MAX_VOLUME = 24 //db

export default class Sound {
  currentMeasure = 0

  constructor() {
    window.addEventListener('keydown', this.handleKeyDown)
  }

  handleKeyDown = (e) => {
    if (e.key === '1') {
      this.stop()
      this.play(SONGS.whistle)
    }
    if (e.key === '2') {
      this.stop()
      this.play(SONGS.wii)
    }
    if (e.key === '3') {
      this.stop()
      this.play(SONGS.ipod)
    }
  }

  // this function must be called in response to a user action
  // otherwise safari and chrome will block the audio
  resume() {
    this.play(SONGS.ipod)
  }

  pause() {
    Transport.stop()
    this.voices?.forEach(voice => voice.player.stop())
  }

  voiceFromFile(file) {
    const voice = {
      file: file,
      player: new Player(`${window.location.origin}${file}`),
      panVol: new PanVol()
    }
    voice.panVol.volume.value = -Infinity
    return voice
  }

  stop() {
    this.pause()
    this.loop?.dispose()
    this.voices?.forEach(voice => {
      voice.player.dispose()
      voice.panVol.dispose()
    })
    this.voices = null
    this.currentMeasure = 0
    this.currentSong = null
  }

  async play(song) {
    // only start if it hasn't started yet
    if (Transport.state === 'started') return
    await start()

    // if song is different from last one, dispose of old voices
    if (this.currentSong && this.currentSong !== song) {
      this.stop()
    }

    this.currentSong = song

    if (!this.voices) {
      const parts = song.parts[0]
      this.voices = parts.map(part => this.voiceFromFile(part[0]))

      // master output
      const reverb = new Reverb(0.5)
      reverb.wet.value = 0.15
      this.masterVolume = new Volume(0).toDestination()
      this.masterVolume.volume.rampTo(MAX_VOLUME, 3)
      this.master = reverb
        .connect(new Compressor())
        .connect(this.masterVolume)

      Transport.bpm.value = song.bpm

      await loaded()

      this.loop = new Loop(time => {
        this.currentMeasure++
        this.voices.forEach((voice, i) => {
          // just step through parts
          const part = song.parts[this.currentMeasure % song.parts.length][i]
          const url = part[0]
          if (url) {
            voice.player.load(url)
          } else {
            voice.player.stop()
          }
          voice.player.chain(voice.panVol)
          voice.panVol.connect(this.master)

          // randomly mute some voices, but keep most on
          const probability = this.currentMeasure <= 2 && typeof part[2] === 'number' ? part[2] : part[1]
          if (Math.random() > probability) {
            voice.panVol.volume.linearRampTo(-Infinity, 0.1)
          } else {
            voice.panVol.volume.linearRampTo(0, 0.1)
          }

          voice.player.start(time)
        })
      }, '2m').start(0)
    }

    // PLAY
    Transport.start()
  }

  // given the state of anybody, modify voices
  async render(anybody) {
    if (!this.voices) return

    // map the x position of each body to a voice's panning
    this.voices.forEach((voice, i) => {
      const body = anybody.bodies[i]
      if (!body) return
      const { x } = body.position

      const xFactor = x / anybody.windowWidth

      // panning
      const panRange = 1.6 // 2 allows hard L/R panning
      voice.panVol.pan.linearRampTo(xFactor * panRange - panRange / 2, 0.1)
    })
  }
}