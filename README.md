# Meeting Report Generator

自動会議レポート生成システム。音声録音から会議の文字起こし、要約、セクション分割、そしてレポート生成までを自動化します。

## 主な機能

- 音声録音からの文字起こし
- LLMを使用した会議内容の要約生成
- エグゼクティブサマリーの生成
- セクション別の要約と整理
- Word形式でのレポート出力

## 必要条件

- Python 3.8以上
- llama.cpp
- Mixtral 8x7B Instructモデル
- Word templateファイル

## セットアップ

1. 必要なPythonパッケージのインストール:
```bash
pip install -r requirements.txt
```

2. llama.cppのセットアップ
3. Mixtral 8x7Bモデルのダウンロード
4. テンプレートファイルの配置

## 使用方法

基本的な使用方法:
```bash
./run_meeting_report.sh <録音ファイル> <出力ディレクトリ>
```

デバッグモード:
```bash
./run_meeting_report.sh <録音ファイル> <出力ディレクトリ> --verbose --step <ステップ番号>
```

## ディレクトリ構造

- `MeetingRecordings/`: 会議録音ファイル
- `MeetingOutputs/`: 生成されたレポート
- `Templates/`: Wordテンプレート
- `models/`: LLMモデル

## ライセンス

MITライセンス 