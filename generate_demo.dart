import 'dart:io';
import 'dart:math';
import 'dart:math' as math;
import 'package:image/image.dart';

/// 将多张图片拼接成N×M的网格图
/// [imagePaths] - 要拼接的图片路径列表
/// [outputPath] - 输出图片路径
/// [rows] - 行数(N)
/// [cols] - 列数(M)
/// [spacing] - 图片之间的间隔(像素)
/// [quality] - 输出JPEG质量(0-100)
Future<void> stitchImages(
  List<String> imagePaths,
  String outputPath, {
  required int rows,
  required int cols,
  int spacing = 0,
  int quality = 85,
}) async {
  if (imagePaths.isEmpty) {
    throw ArgumentError('图片列表不能为空');
  }

  // 读取所有图片并调整到相同大小
  final images = <Image>[];
  int? cellWidth, cellHeight;

  for (final path in imagePaths) {
    final bytes = await File(path).readAsBytes();
    var image = decodeImage(bytes)!;
    
    // 如果是第一张图片，确定单元格大小
    if (cellWidth == null || cellHeight == null) {
      cellWidth = image.width;
      cellHeight = image.height;
    }
    
    // 调整图片大小以匹配第一张图片的尺寸
    if (image.width != cellWidth || image.height != cellHeight) {
      image = copyResize(image, width: cellWidth!, height: cellHeight!);
    }
    
    images.add(image);
  }

  // 计算最终画布大小
  final totalWidth = cellWidth! * cols + spacing * (cols - 1);
  final totalHeight = cellHeight! * rows + spacing * (rows - 1);
  
  // 创建新图像
  final result = Image(width: totalWidth, height: totalHeight);
  
  // 将图片拼接到网格中
  for (int i = 0; i < images.length; i++) {
    final row = i ~/ cols;
    final col = i % cols;
    
    final x = col * (cellWidth + spacing);
    final y = row * (cellHeight + spacing);
    
    // 将图片复制到结果图像中
    compositeImage(result, images[i], dstX: x, dstY: y);
  }

  // 保存结果图像
  final outputFile = File(outputPath);
  await outputFile.writeAsBytes(encodeJpg(result, quality: quality));
  
  print('图片拼接完成，保存到: $outputPath');
}

/// 遍历指定文件夹，获取所有PNG图片路径
/// [folderPath] - 文件夹路径
/// 返回PNG图片路径列表
List<String> getPngImagesFromFolder(String folderPath) {
  final folder = Directory(folderPath);
  
  // 检查文件夹是否存在
  if (!folder.existsSync()) {
    throw ArgumentError('文件夹不存在: $folderPath');
  }
  
  // 获取所有PNG文件
  final pngFiles = folder
      .listSync()
      .where((file) => 
          file is File && 
          file.path.toLowerCase().endsWith('.png'))
      .map((file) => file.path)
      .toList();
  
  // 按文件名排序，确保拼接顺序一致
  pngFiles.sort();
  
  print('在 $folderPath 中找到 ${pngFiles.length} 张PNG图片');
  return pngFiles;
}

/// 根据图片数量计算最佳的网格布局
/// [imageCount] - 图片总数
/// 返回 [rows, cols] 数组
List<int> calculateOptimalGrid(int imageCount) {
  if (imageCount <= 0) {
    return [0, 0];
  }
  
  // 计算最接近正方形的网格布局
  final sqrt = math.sqrt(imageCount);
  int cols = sqrt.ceil();
  int rows = (imageCount / cols).ceil();
  
  // 如果行数太少，调整布局使其更平衡
  if (rows * cols - imageCount > cols ~/ 2) {
    cols = sqrt.floor();
    rows = (imageCount / cols).ceil();
  }
  
  print('为 $imageCount 张图片计算出最佳网格布局: ${rows}x${cols}');
  return [rows, cols];
}

/// 主函数：遍历screenshot文件夹并拼接所有PNG图片
/// [screenshotFolder] - screenshot文件夹路径，默认为 './screenshot'
/// [outputPath] - 输出文件路径，默认为 './stitched_images.jpg'
/// [spacing] - 图片间隔，默认为5像素
/// [quality] - JPEG质量，默认为90
Future<void> stitchScreenshots({
  String screenshotFolder = './screenshot',
  String outputPath = './stitched_images.jpg',
  int spacing = 5,
  int quality = 90,
}) async {
  try {
    // 获取所有PNG图片路径
    final imagePaths = getPngImagesFromFolder(screenshotFolder);
    
    if (imagePaths.isEmpty) {
      print('在 $screenshotFolder 文件夹中没有找到PNG图片');
      return;
    }
    
    // 计算最佳网格布局
    final grid = calculateOptimalGrid(imagePaths.length);
    final rows = grid[0];
    final cols = grid[1];
    
    print('开始拼接图片...');
    
    // 执行图片拼接
    await stitchImages(
      imagePaths,
      outputPath,
      rows: rows,
      cols: cols,
      spacing: spacing,
      quality: quality,
    );
    
    print('✅ 成功拼接 ${imagePaths.length} 张图片');
    print('📁 输出文件: $outputPath');
    
  } catch (e) {
    print('❌ 拼接图片时发生错误: $e');
  }
}

/// 程序入口点
void main() async {
  // 拼接screenshot文件夹中的所有PNG图片
  await stitchScreenshots(
    screenshotFolder: './demo/screenshot',
    outputPath: './demo/stitched_images.jpg',
    spacing: 5,
    quality: 90,
  );
}