@{
    ExcludeRules = @(
        # .editorconfig で charset = utf-8（BOM 無し）と決めているため、BOM を要求する規則と衝突する
        'PSUseBOMForUnicodeEncodedFile'

        # スタイルの好みであり実害が薄い
        'PSAvoidUsingPositionalParameters'
    )
}
