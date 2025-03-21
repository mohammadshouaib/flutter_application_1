// class CommentSection extends StatelessWidget {
//   final List<Comment> comments;

//   const CommentSection({Key? key, required this.comments}) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       children: comments.map((comment) {
//         return ListTile(
//           leading: CircleAvatar(
//             backgroundImage: CachedNetworkImageProvider(comment.user.profileImageUrl),
//           ),
//           title: Text(comment.user.name),
//           subtitle: Text(comment.text),
//           trailing: Text(comment.timestamp.toString()),
//         );
//       }).toList(),
//     );
//   }
// }