$filename = "node-ssl.tar"
$partSize = 48MB  # 每个部分的大小

# 获取文件的字节内容
$content = [System.IO.File]::ReadAllBytes(".\$filename")

# 计算切分后的部分数量
$totalParts = [Math]::Ceiling($content.Length / $partSize)

# 切分文件
for ($i = 0; $i -lt $totalParts; $i++) {
    $start = $i * $partSize
    $end = [Math]::Min(($i + 1) * $partSize, $content.Length)
    $partContent = $content[$start..($end - 1)]
    [System.IO.File]::WriteAllBytes(".\$filename.part$($i+1)", $partContent)
}
