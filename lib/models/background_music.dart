//Custom Class: BackgroundMusic
//This class represents background music option.
class BackgroundMusic {
  final String title;
  final String musicPath;

  //Background music constructor.
  const BackgroundMusic({required this.title, required this.musicPath});
}

//List that stores all background music songs.
const List<BackgroundMusic> backgroundMusicList = [
  //BackgroundMusic is optional.
  BackgroundMusic(title: 'No Background Music', musicPath: ''),
  BackgroundMusic(
    title: 'Bluebonnet',
    musicPath: 'background_music/bluebonnet.wav',
  ),
  BackgroundMusic(title: 'Etirwer', musicPath: 'background_music/etirwer.wav'),
  BackgroundMusic(
    title: 'Forget Me Not',
    musicPath: 'background_music/forget_me_not.wav',
  ),
  BackgroundMusic(title: 'Piano', musicPath: 'background_music/piano.wav'),
  BackgroundMusic(
    title: 'The Old Tower Inn',
    musicPath: 'background_music/the_old_tower_inn.wav',
  ),
  BackgroundMusic(
    title: 'Waiting III',
    musicPath: 'background_music/waiting_iii.wav',
  ),
];
