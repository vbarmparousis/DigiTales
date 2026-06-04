//Import Packages
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'dart:io';

//My Imports
import '../models/story.dart';
import 'story_details_page.dart';

//Statefull Widget rebuilds the screen
//changes with setstate((){});
class StoriesListPage extends StatefulWidget{

  const StoriesListPage({super.key});

  @override
  State<StoriesListPage> createState() => _StoriesListPageState();
}

class _StoriesListPageState extends State<StoriesListPage> {

  //Controls search TexField.
  final TextEditingController _searchController = TextEditingController();

  //Stores current search text.
  String searchText='';

  //Stores current sorting option.
  String sortingOption = 'A-Z';

  //Formats audio duration into HH:MM:SS format.
  String formatTime(int seconds){
    return Duration(seconds: seconds)
        .toString()
        .split('.')
        .first
        .padLeft(8, '0');
  }


  @override
  void dispose() {
    //Free memory from search controller.
    _searchController.dispose();
    //Calls parent class dispose method to complete cleanup
    super.dispose();
  }



  @override
  Widget build(BuildContext context) {

    //Grants access to Hive Story Box
    final storyBox=Hive.box('storyBox');

    //Creates a temporary list with all stories loaded from Hive.
    final List<Story> allStoriesList = [];

    //Loads all stories from Hive and turns them into Story objects.
    //The key is needed so edit/delete works correctly after filtering.
    for (final key in storyBox.keys){
      final loadedStory = storyBox.get(key);
      allStoriesList.add(
        Story(
          title: loadedStory['title'],
          description: loadedStory['description'],
          storyAudio: loadedStory['storyAudio'],
          coverImage: loadedStory['coverImage'] ??'',
          audioDuration: loadedStory['audioDuration'] ?? 0,
          hiveKey: key,
        ),
      );
    }

    //Filters stories based on the search text.
    final filteredStories = allStoriesList.where((story){
      return story.title.toLowerCase().contains(searchText);
    }).toList();

    //Sorts Stories Alphabetically.
    if (sortingOption == 'A-Z') {
      filteredStories.sort(
          (a,b) => a.title.compareTo(b.title),
      );
    }

    //Sorts Stories Reversed Alphabetically.
    else if (sortingOption == 'Z-A') {
      filteredStories.sort(
            (a,b) => b.title.compareTo(a.title),
      );
    }
    //Sorts Stories by shortest Duration.
    else if (sortingOption == 'Shortest') {
      filteredStories.sort(
            (a,b) => a.audioDuration.compareTo(b.audioDuration),
      );
    }
    //Sorts Stories by longest Duration.
    else if (sortingOption == 'Longest') {
      filteredStories.sort(
            (a,b) => b.audioDuration.compareTo(a.audioDuration),
      );
    }


    return Scaffold(
      appBar: AppBar(

        //Same Background as the Home Page
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text ('Library'),
      ),

      body:  Padding(
        padding: const EdgeInsets.all(24),
        child:Column(
          children: [

        //Search TextField
        TextField(
            controller: _searchController,
          decoration: InputDecoration(
            hintText:'Search Stories',
            prefixIcon: const Icon(Icons.search),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(35),
            ),
          ),
          onChanged: (value){
              setState(() {
                //Converts search text to lowercase
                //for case-insensitive searching.
                searchText= value.toLowerCase();
              });
          },
        ),


        const SizedBox(height: 16),

        //Sorting Dropdown
        DropdownButtonFormField<String>(
          initialValue: sortingOption,

          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(35),
            ),
          ),

          //Shorting Dropdown
          items: const [
            DropdownMenuItem(
                value:'A-Z',
                child: Text('Sort A-Z'),
            ),

            DropdownMenuItem(
              value:'Z-A',
              child: Text('Sort Z-A'),
            ),

            DropdownMenuItem(
              value:'Shortest',
              child: Text('Sortest First'),
            ),

            DropdownMenuItem(
              value:'Longest',
              child: Text('Longest First'),
            ),
          ],

          onChanged: (value){
            setState(() {
              sortingOption=value!;
            });
          },
        ),

        const SizedBox(height: 32),



        Expanded(
          child: storyBox.isEmpty ?
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.book_rounded,
              size: 100,
              color: Colors.teal,
            ),
          const Text(
            'There are no stories yet.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 24),
          ),
          ],
            ),
          )

              :filteredStories.isEmpty
          ? const Center(
            child: Text(
              'No stories found.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20),
            ),
          )
          : ListView.builder(
            //Uses widget to get access to stories in this State
            itemCount: filteredStories.length,
              itemBuilder: (context, index) {

                //Gets one filtered story from search results.
                final story = filteredStories[index];

                return Card(
                  child: ListTile(
                    leading: story.coverImage.isNotEmpty
                      ? ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.file(
                          File(story.coverImage),
                          height: 60,
                          width: 60,
                          fit: BoxFit.cover
                        ),
                      )
                      :const Icon(Icons.book_rounded),


                    title: Text(
                        story.title,
                      maxLines:1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle:
                    //Text(story.description),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          story.description,
                          maxLines:1,
                          overflow: TextOverflow.ellipsis,),

                        Row(
                          children: [
                            const Icon(
                              Icons.access_time_rounded,
                              size: 16,
                              color: Colors.grey,
                            ),
                        const SizedBox(width:4),

                        //Show Duration in ListTile.
                        Text(
                          formatTime(story.audioDuration),
                          style: const TextStyle(
                            color: Colors.grey,
                          )
                        ),
                  ],
                        ),
                      ],

                    ),

                    onTap: () async {
                      //Opens the Story Details Page for a chosen story
                      //Waits for the Delete Story or Edit Story Answer.
                      var deleteOrEdit = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              StoryDetailsPage(
                                story: story,
                              ),
                        ),
                      );
                      //If Story Deletion is selected,
                      // it removes the story from the list
                      //and rebuilds the Stories List Page.
                      if (deleteOrEdit != null) {
                        if (deleteOrEdit == 'delete') {
                          setState(() {
                            storyBox.delete(story.hiveKey);
                          });
                        } else if (deleteOrEdit is Story) {
                          setState(() {
                            storyBox.put(story.hiveKey, {
                              'title': deleteOrEdit.title,
                              'description': deleteOrEdit.description,
                              'storyAudio': deleteOrEdit.storyAudio,
                              'coverImage': deleteOrEdit.coverImage,
                              'audioDuration': deleteOrEdit.audioDuration,
                            });
                          }
                          );
                        }
                      }
                    },
                      ),
                );

              },
          ),
        ),
            ],
            ),
      ),
    );
  }
}
