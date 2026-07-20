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
  BackgroundMusic(
    title: 'No Background Music',
    musicPath: '',
  ),
  BackgroundMusic(
    title: 'The Old Tower Inn',
    musicPath: 'background_music/Loop_The_Old_Tower_Inn.wav',
  ),
];
