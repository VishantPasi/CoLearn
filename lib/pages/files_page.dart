import 'dart:async';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:colearn/apis.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get_storage/get_storage.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';

class Files extends StatefulWidget {
  final String teacherUid;
  final String folderName;
  const Files({super.key, required this.teacherUid, required this.folderName});

  @override
  State<Files> createState() => _FilesState();
}

class _FilesState extends State<Files> {
  final StreamController<List<String>> fileStreamController =
      StreamController<List<String>>();
  final GlobalKey<ScaffoldState> scaffoldKey2 = GlobalKey<ScaffoldState>();
  final userDetailsBox = GetStorage();
  bool isUploading = false;
  double uploadProgress = 0.0;
  String? uploadingFileName;
  bool isDownloading = false;
  String downloadStatus = '';
  // String filePath1 = '';
  String? currentlyDownloadingFile;
  double downloadProgress = 0.0;
  double usedStorageInBytes = 0.0;

  String? selectedFileName; // Store the selected file name
  String? selectedFileType; // Store the selected file type
  String? selectedFileSize; // Store the selected file size

  snackBarContainer(snackBarText) {
    return ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20), topRight: Radius.circular(20))),
        backgroundColor: const Color.fromARGB(255, 190, 13, 0),
        dismissDirection: DismissDirection.down,
        duration: const Duration(seconds: 3),
        content: Center(
          child: Text(snackBarText,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 19)),
        )));
  }

  Future<void> updateFolderItems() async {
    ListResult result = await FirebaseStorage.instance
        .ref()
        .child("${widget.teacherUid}/${widget.folderName}/")
        .listAll();
    List<String> fileName = result.items
        .map((item) => item.name)
        .where((name) => name != 'description.txt') // Ignore specific file
        .toList();
    fileStreamController.add(fileName);
  }

  Future<void> calculateUsedStorage([Reference? reference]) async {
    reference ??=
        FirebaseStorage.instance.ref().child("${APIs.auth.currentUser!.uid}/");

    try {
      // List all files in the current directory
      final ListResult result = await reference.listAll();

      // Fetch metadata for all files in parallel
      final List<Future<FullMetadata>> metadataFutures =
          result.items.map((item) => item.getMetadata()).toList();
      final List<FullMetadata> metadataList =
          await Future.wait(metadataFutures);

      // Sum up the sizes from the fetched metadata

      usedStorageInBytes +=
          metadataList.fold(0, (sum, metadata) => sum + (metadata.size ?? 0));

      // Recursively list all subdirectories and their files
      final List<Future<void>> folderFutures = result.prefixes
          .map((folder) => calculateUsedStorage(folder))
          .toList();
      await Future.wait(folderFutures);

      setState(() {});
    } catch (e) {
      snackBarContainer('Error calculating storage usage: $e');
    }
  }

  Future<void> uploadFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: [
          'jpg',
          'jpeg',
          'png',
          'gif',
          'pdf',
          'docx',
          'doc',
          'pptx',
          'ppt'
        ]);

    if (result == null) return;

    String filePath = result.files.single.path!;
    String fileName = result.files.single.name;

    Reference storageRef = FirebaseStorage.instance
        .ref()
        .child("${APIs.auth.currentUser!.uid}/${widget.folderName}/$fileName");

    setState(() {
      isUploading = true;
      uploadProgress = 0.0;
      uploadingFileName = fileName;
    });
    UploadTask uploadTask = storageRef.putFile(File(filePath));

    uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
      setState(() {
        uploadProgress = snapshot.bytesTransferred.toDouble() /
            snapshot.totalBytes.toDouble();
      });
    });

    try {
      await uploadTask;
      // Ensure the folder items are updated after the upload completes
      await updateFolderItems(); // Refresh the file list
      setState(() {
        isUploading = false;
        uploadingFileName = null;
      });
    } catch (e) {
      setState(() {
        isUploading = false;
        uploadingFileName = null;
      });
    }
  }

  Future<void> onRefresh() async {
    await updateFolderItems();
  }

  Future<void> deleteFile(String fileName) async {
    try {
      Reference fileRef = FirebaseStorage.instance
          .ref()
          .child("${widget.teacherUid}/${widget.folderName}/$fileName");
      await fileRef.delete();
      updateFolderItems(); // Refresh the file list

      snackBarContainer('File deleted successfully');
    } catch (e) {
      snackBarContainer('Error deleting file: $e');
    }
  }

  Future<void> downloadFile(String fileName) async {
    try {
      updateFolderItems();
      setState(() {
        isDownloading = true;
        downloadStatus = "Downloading...";
        currentlyDownloadingFile = fileName;
        downloadProgress = 0.0;
      });

      // Get the external storage directory specific to your app
      Directory? appExternalDir = await getExternalStorageDirectory();
      if (appExternalDir == null) {
        setState(() {
          isDownloading = false;
          downloadStatus = "Failed to get external storage directory";
        });
        return;
      }

      // Set the file path dynamically for each file
      String filePath = '${appExternalDir.path}/$fileName';

      // Check if the file already exists
      File file = File(filePath);
      if (await file.exists()) {
        // If the file exists, open it directly
        openFile(filePath);
        return;
      }

      // Get the download URL from Firebase Storage
      String fileUrl = await FirebaseStorage.instance
          .ref("${widget.teacherUid}/${widget.folderName}/$fileName")
          .getDownloadURL();

      FirebaseStorage.instance
          .refFromURL(fileUrl)
          .writeToFile(file)
          .snapshotEvents
          .listen((event) {
        setState(() {
          downloadProgress = event.bytesTransferred / event.totalBytes;
        });
      }, onDone: () {
        setState(() {
          isDownloading = false;
          downloadStatus = "Download Complete! File saved to $filePath";
          currentlyDownloadingFile = null;
          downloadProgress = 0.0; // Reset after download completes
        });
        openFile(filePath); // Open the file after downloading
      }, onError: (error) {
        setState(() {
          isDownloading = false;
          downloadStatus = "Error downloading file: $error";
          currentlyDownloadingFile = null;
        });
      });
    } catch (e) {
      setState(() {
        isDownloading = false;
        downloadStatus = "Error downloading file: $e";
      });
    }
  }

  Future<void> openFile(String filePath) async {
    final file = File(filePath);

    if (await file.exists()) {
      await OpenFile.open(filePath);
      setState(() {
        isDownloading = false;
        currentlyDownloadingFile = null;
      });
    } else {
      snackBarContainer('File does not exist at $filePath');
    }
  }

  Future<void> fetchFileDetails(String fileName) async {
    Reference fileRef = FirebaseStorage.instance
        .ref()
        .child("${widget.teacherUid}/${widget.folderName}/$fileName");

    fileRef.getMetadata().then((metadata) {
      setState(() {
        selectedFileName = fileName;
        selectedFileType = metadata.contentType;
        selectedFileSize = (metadata.size! / (1024 * 1024)).toStringAsFixed(2);
      });
      scaffoldKey2.currentState!.openEndDrawer();
    }).catchError((error) {
      snackBarContainer('Error fetching file details: $error');
    });
  }

  @override
  void initState() {
    updateFolderItems();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldKey2,
      backgroundColor: const Color.fromARGB(255, 27, 30, 68),
      body: RefreshIndicator(
        onRefresh: onRefresh,
        child: StreamBuilder<List<String>>(
          stream: fileStreamController.stream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            } else if ((!snapshot.hasData || snapshot.data!.isEmpty) &&
                isUploading == false) {
              return Padding(
                padding: const EdgeInsets.all(60.0),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Image.asset(
                        "assets/images/no_data_found.png",
                      ),
                      const Text(
                        "No Files Found!",
                        style: TextStyle(
                            color: Colors.white,
                            fontFamily: "RobotoMono",
                            fontSize: 20),
                      )
                    ],
                  ),
                ),
              );
            } else {
              return GridView.builder(
                padding: const EdgeInsets.all(8.0),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2, // Number of columns
                  crossAxisSpacing: 10.0, // Horizontal space between grid items
                  mainAxisSpacing: 10.0, // Vertical space between grid items
                  childAspectRatio:
                      0.9, // Aspect ratio of the items (width/height)
                ),
                itemCount: snapshot.data!.length + (isUploading ? 1 : 0),
                itemBuilder: (context, index) {
                  if (isUploading && index == 0) {
                    // Show upload progress indicator at the top of the grid
                    return Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30),
                        color: Colors.white,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const SizedBox(height: 10),
                          CircularPercentIndicator(
                            percent: uploadProgress,
                            radius: 50,
                            lineWidth: 6,
                            progressColor: Colors.red,
                          ),
                          const SizedBox(height: 5),
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Text(
                              uploadingFileName ?? "Uploading file...",
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  // Adjust index if upload placeholder is at the top
                  int fileIndex = isUploading ? index - 1 : index;

                  String fileName = snapshot.data![fileIndex];
                  String fileExtension = fileName.split('.').last.toLowerCase();
                  late Widget filePreview;

                  if (['jpg', 'jpeg', 'png', 'gif'].contains(fileExtension)) {
                    // Display image preview
                    filePreview = FutureBuilder<String>(
                      future: FirebaseStorage.instance
                          .ref(
                              "${widget.teacherUid}/${widget.folderName}/$fileName")
                          .getDownloadURL(),
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return const Icon(Icons.broken_image, size: 50);
                        } else if (!snapshot.hasData) {
                          return Image.asset(
                            'assets/images/img_alt.png',
                            width: 120,
                          );
                        } else {
                          return ClipRRect(
                              borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(20),
                                  topRight:
                                      Radius.circular(20)), // Round the corners
                              child: CachedNetworkImage(
                                imageUrl: snapshot.data!,
                                placeholder: (context, url) => Image.asset(
                                  'assets/images/img_alt.png',
                                  width: 120,
                                ),
                                errorWidget: (context, url, error) =>
                                    const Icon(Icons.broken_image, size: 50),
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: double.infinity,
                              ));
                        }
                      },
                    );
                  } else if (fileExtension == 'pdf') {
                    // Display PDF icon
                    filePreview = Image.asset(
                      'assets/images/pdf_alt.png',
                      width: 120,
                    );
                  } else if (fileExtension == 'docx' ||
                      fileExtension == "doc") {
                    // Display PDF icon
                    filePreview = Image.asset(
                      'assets/images/docx_alt.png',
                      width: 120,
                    );
                  } else if (fileExtension == 'pptx' ||
                      fileExtension == "ppt") {
                    // Display PDF icon
                    filePreview = Image.asset(
                      'assets/images/ppt_alt.png',
                      width: 120,
                    );
                  } else {
                    // Display PDF icon
                    filePreview = Image.asset(
                      'assets/images/unknown.png',
                      width: 120,
                    );
                  }
                  return GestureDetector(
                    onTap: () => downloadFile(fileName),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          color: Colors.white,
                        ),
                        child: GridTile(
                          header: Padding(
                            padding: const EdgeInsets.symmetric(
                                vertical: 8.0, horizontal: 5),
                            child: Align(
                              alignment: Alignment.topRight,
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  if (isDownloading &&
                                      currentlyDownloadingFile == fileName)
                                    CircularPercentIndicator(
                                      radius: 15.0,
                                      lineWidth: 4.0,
                                      percent: downloadProgress,
                                      progressColor:
                                          userDetailsBox.read("role") ==
                                                  "Teacher"
                                              ? Colors.red
                                              : const Color.fromRGBO(
                                                  58, 141, 255, 1),
                                    ),
                                  const SizedBox(),
                                ],
                              ),
                            ),
                          ),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Expanded(
                                    child: Container(
                                        decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(20),
                                            border: const BorderDirectional(
                                                start: BorderSide(
                                                    color: Colors.white,
                                                    width: 2),
                                                top: BorderSide(
                                                    color: Colors.white,
                                                    width: 2),
                                                end: BorderSide(
                                                    color: Colors.white,
                                                    width: 2))),
                                        child: filePreview)),
                                Divider(
                                  height: 5,
                                  thickness: 5,
                                  color: userDetailsBox.read("role") ==
                                          "Teacher"
                                      ? const Color.fromRGBO(196, 58, 79, 1)
                                      : const Color.fromRGBO(58, 141, 255, 1),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Flexible(
                                        child: Text(
                                          fileName,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          textAlign: TextAlign.start,
                                          style: const TextStyle(
                                            color: Colors.black,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      IconButton(
                                          icon: Icon(
                                              FontAwesomeIcons.ellipsisVertical,
                                              size: 20,
                                              color:
                                                  userDetailsBox.read("role") ==
                                                          "Teacher"
                                                      ? Colors.red
                                                      : const Color.fromRGBO(
                                                          58, 141, 255, 1)),
                                          onPressed: () =>
                                              fetchFileDetails(fileName)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            }
          },
        ),
      ),
      endDrawer: Drawer(
        backgroundColor: const Color.fromARGB(244, 72, 73, 148),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 150,
              decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 33, 36, 83),
                  border: BorderDirectional(
                      bottom: BorderSide(
                          color: userDetailsBox.read("role") == "Teacher"
                              ? Colors.red
                              : const Color.fromRGBO(58, 141, 255, 1),
                          width: 2))),
              child: const Center(
                child: Text(
                  'File Details',
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontFamily: "RobotoMono"),
                ),
              ),
            ),
            if (selectedFileName != null)
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    const Text(
                      "File Name:",
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold),
                    ),
                    Text(
                      selectedFileName!,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontFamily: "RobotoSlab"),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      "File Type:",
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold),
                    ),
                    Text(
                      selectedFileType!.toUpperCase(),
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontFamily: "RobotoSlab"),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      "File Size:",
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '${selectedFileSize ?? 'Unknown'} MB',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontFamily: "RobotoSlab"),
                    ),
                  ],
                ),
              ),
            const Spacer(),
            Padding(
                padding: const EdgeInsets.all(16.0),
                child: userDetailsBox.read("role") == "Teacher"
                    ? Container(
                        decoration: BoxDecoration(
                            color: const Color.fromARGB(255, 27, 30, 68),
                            borderRadius: BorderRadius.circular(30)),
                        child: IconButton(
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                backgroundColor:
                                    const Color.fromRGBO(182, 54, 73, 1),
                                title: const Text(
                                  'Delete File',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: "RobotoMono"),
                                ),
                                content: Text(
                                  'Are you sure you want to delete $selectedFileName ?',
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontFamily: "RobotoSlab"),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                    },
                                    child: const Text(
                                      'Cancel',
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontFamily: "RobotoMono",
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                      Navigator.of(context).pop();
                                      deleteFile(selectedFileName!);
                                    },
                                    child: const Text('Yes',
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontFamily: "RobotoMono",
                                            fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              ),
                            );
                          },
                          icon: const FaIcon(
                            FontAwesomeIcons.solidTrashCan,
                            color: Colors.red,
                          ),
                        ),
                      )
                    : const Text("")),
          ],
        ),
      ),
      floatingActionButton: userDetailsBox.read("role") == "Teacher"
          ? FloatingActionButton(
              onPressed: () async {
                await calculateUsedStorage();
                if (usedStorageInBytes <= (1024 * 1024 * 1024)) {
                  //no. of bytes in 1 gb
                  uploadFile();
                } else {
                  setState(() {
                    usedStorageInBytes = 0;
                  });
                  snackBarContainer("Storage limit exceeded");
                }
              },
              backgroundColor: const Color.fromARGB(235, 72, 73, 148),
              child: const Icon(
                Icons.add,
                color: Color.fromARGB(255, 255, 224, 131),
                size: 30,
              ),
            )
          : null,
    );
  }
}
