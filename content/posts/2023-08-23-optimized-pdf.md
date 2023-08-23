+++
title = "Optimized PDF"
date = 2023-08-23T10:55:04+08:00
tags = ["latex"]
categories = ["work"]
draft = false
+++

无意中，看到生成出来的 pdf 文件的属性中有这么一段：

```sh
Optimized:  No
```

这好奇心和强迫症一下就升腾上来了。我呕心沥血写的 Xelatex 文本，仔仔细
细地修复了 _Underfull_ 和 _Overfull_ 报警，为啥会有这么个碍眼的 No?

### 什么是 Optimized PDF?

TUG 邮件列表有人曾经也[问了这个问题](https://tug.org/pipermail/xetex/2008-January/008322.html), 
简单来说 Properties 里面显示的这个 `Optimized` 准确来说，应该是
`Linearized` 的意思，或者叫 `Web-optimized`.

普通 PDF 文件的索引表（`xref table`, 包含 pdf 文件内各个对象的偏移地址）
是放在文件末尾的。这样浏览器打开 pdf 时，需要等文件下载完成才能显示出
来。如果索引表放在文件开头，且 PDF 文件内的对象按偏移排序，就能实现提
前显示文档内容。

### 如何变成 Optimized?

对 PDF 文件的对象做排序是个事后处理过程，所有的 TeX engine 都不会做这
个事情。有很多工具可以用来做这个 post-processing.

```sh
$ qpdf --linearize input.pdf optimized.pdf
```

这么处理以后，pdf 文件的尺寸可能反而稍微变大。因此，可以启用压缩：

```sh
$ qpdf --linearize --object-streams=generate --optimize-images \
       --compress-streams=y --compression-level=9 --recompress-flate \
	   input.pdf optimized.pdf
```

### Optimizing PDFs with Ghostscript

Ghostscript 官网的[优化建议](https://www.ghostscript.com/blog/optimizing-pdfs.html)非常有信息含量。
首先，“优化” 这个词对于不同的用户可能有不同的含义，可能是：

- Fast web view: `-dFastWebView`;
- Minimise file size: `-dPDFSETTINGS=configuration`
- Conforming to a subset of the PDF specification (e.g., PDF/A `-DPDFA`)
- Produce a PDF file without errors: `-dPDFSTOPONERROR` and `-dPDFSTOPONWARNING`

其中，`-dPDFSETTINGS` 的 `configuration` 参数可以是：

- `/screen` - 72 DPI, 面向低分辨率输出设备；
- `/ebook` - 150 DPI, 面向中等分辨率输出设备；
- `/printer` - 300 DPI, 类似 Acrobat Distiller "Prepress Optimized".
- `/press` - 300 DPI，类似 Acrobat Distiller "Print Optimized".
- `/default` - 默认设置。

上面每项设置具体影响的输出参数可以在[官网文档](https://ghostscript.readthedocs.io/en/latest/VectorDevices.html#distiller-parameters)找到。
和之前使用 `qpdf` 做压缩不同的是，应用 `-dPDFSETTINGS` 可能会改变 PDF
的显示质量。比如，指定 `/ebook` 虽然可以使输出的 PDF 文件小很多，但字
体的 DPI (Dots Per Inch) 和图片的分辨率都会受影响。因此，可以精细化指
定 `gs` 参数，比如：

```sh
$ gs -sDEVICE=pdfwrite -dFastWebView -dPDFSETTINGS=/ebook \
     -dColorImageResolution=300 -dGrayImageResolution=300 \
	 -dNOPAUSE -dQUIET -dBATCH \
	 -sOutputFile=optimized.pdf input.pdf
```

上面的例子中，指定 `/ebook` 后又额外设置了图片的分辨率。[这里](https://askubuntu.com/questions/113544/how-can-i-reduce-the-file-size-of-a-scanned-pdf-file)有更多花式用法。

### 乱码问题

用 `gs` 处理了一番之后，PDF 元数据中的 `Title` 和 `Author` 中文信息变
成了乱码。看起来，这是个[BUG](https://bugs.ghostscript.com/show_bug.cgi?id=693400), 
以及[参考](https://unix.stackexchange.com/questions/50475/how-to-make-ghostscript-not-wipe-pdf-metadata)。

从[贴子](https://stackoverflow.com/questions/9188189/wrong-encode-when-update-pdf-meta-data-using-ghostscript-and-pdfmark)得知，
PDF 文档 `info dictionary` 中的文本字段需要是 `PDFDocEncoding` 处理过，
或者 `UTF-16BE with a Byte Order Mark (BOM)`. 一番操作后，发现了新世界：

- 指定 pdfmarks, 其中包含带 UTF-16BE with BOM 编码的 Title 和
  Author. 重新用 `gs` 处理后，用 `evince` 看，仍然是乱码；
- Nautilus 文件浏览器看到的 pdf 属性里面，这两个元数据里的中文也是乱码；
- 用 pdfinfo 输出元数据，发现中文显示正常，和没有指定编码后的
  pdfmarks 时一样；
- `gs` 处理后的 PDF 用 firefox 或者 SumatraPDF 查看元数据，中文并没有
  乱码。

究竟是 viewer 的问题，还是 model 的问题，还没有定论。T_T
