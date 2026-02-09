# go-sqlcipher-vec

`go-sqlcipher-vec` 是一个 Go 语言 SQLite3 驱动（兼容标准库 `database/sql`），基于 [mattn/go-sqlite3](https://github.com/mattn/go-sqlite3) 通过 CGO **静态集成**：

- SQLCipher（数据库透明加密，AES-256）
- sqlite-vec（向量检索扩展，`vec0` 虚表）
- libtomcrypt（SQLCipher 底层加密实现，项目：https://github.com/libtom/libtomcrypt ，说明：一个可移植的密码学库集合，提供多种对称/非对称加密、哈希、MAC 等算法实现，SQLCipher 在本项目中通过它获得底层密码学能力）

本项目参考 `github.com/Boolean-Autocrat/go-sqlcipher` 进行修改以适配新版 SQLCipher，并增加向量扩展。

该项目提供一个**自包含**方案：你无需在系统中额外安装 SQLite/SQLCipher 动态库，即可在 Go 项目中实现「加密存储 + 向量检索」。

---

## 核心特性

- 透明加密：对整个数据库文件进行 AES-256 加密
- 向量检索：内置 `sqlite-vec`，支持向量相似度计算（L2、余弦等）与 KNN 查询
- 自包含：静态链接所有 C 依赖（需启用 CGO）
- 标准接口：兼容 `database/sql`（可配合 GORM 等 ORM 使用）

---

## 前置条件

- 需要启用 CGO
- 需要可用的 C 编译器

常见平台：

- macOS：安装 Xcode Command Line Tools（`xcode-select --install`）
- Linux：安装 `gcc`/`clang` 与基础构建工具
- Windows：安装 MinGW-w64 或使用 MSVC 工具链（确保 `cgo` 可用）

---

## 安装

```bash
go get github.com/lujihong/go-sqlcipher-vec
```

---

## 快速上手

### 1) 打开/创建加密数据库

可以通过 DSN（数据源名称）参数配置密钥与 SQLCipher 相关 PRAGMA。

#### 使用 Hex 编码密钥（推荐）

```go
package main

import (
	"database/sql"
	"fmt"

	_ "github.com/lujihong/go-sqlcipher-vec"
)

func main() {
	// 32 字节（64 个字符）的十六进制密钥
	key := "2DD29CA851E7B56E4697B0E1F08507293D761A05CE4D1B628663F411A8086D99"
	// _key=x'...': 以 blob 形式传入
	// _pragma_cipher_page_size: 示例 PRAGMA（按需调整）
	dsn := fmt.Sprintf("file:secure.db?_key=x'%s'&_pragma_cipher_page_size=4096", key)

	db, err := sql.Open("sqlite3", dsn)
	if err != nil {
		panic(err)
	}
	defer db.Close()

	if err := db.Ping(); err != nil {
		panic(err)
	}
}
```

#### 使用普通文本密码

```go
package main

import (
	"database/sql"
	"fmt"
	"net/url"

	_ "github.com/lujihong/go-sqlcipher-vec"
)

func main() {
	passphrase := url.QueryEscape("your-password")
	dsn := fmt.Sprintf("file:secure.db?_key=%s", passphrase)

	db, err := sql.Open("sqlite3", dsn)
	if err != nil {
		panic(err)
	}
	defer db.Close()

	if err := db.Ping(); err != nil {
		panic(err)
	}
}
```

### 2) 向量检索（sqlite-vec）

`go-sqlcipher-vec` 会自动注册向量扩展。你可以创建 `vec0` 虚表并进行相似度查询。

#### 创建向量表

```sql
CREATE VIRTUAL TABLE vec_items USING vec0(
  sample_embedding float[3]
);
```

#### 插入与查询向量

项目提供 `SerializeFloat32Param` 辅助函数，确保向量数据以正确的 `subtype` 传递给 SQLite。

```go
package main

import (
	"database/sql"
	"fmt"

	sqlite3 "github.com/lujihong/go-sqlcipher-vec"
)

func main() {
	db, err := sql.Open("sqlite3", "file:vec.db")
	if err != nil {
		panic(err)
	}
	defer db.Close()

	_, err = db.Exec(`
		CREATE VIRTUAL TABLE IF NOT EXISTS vec_items USING vec0(
			sample_embedding float[3]
		);
	`)
	if err != nil {
		panic(err)
	}

	vec := []float32{0.1, 0.2, 0.3}
	param, err := sqlite3.SerializeFloat32Param(vec)
	if err != nil {
		panic(err)
	}

	_, err = db.Exec("INSERT INTO vec_items(sample_embedding) VALUES (?)", param)
	if err != nil {
		panic(err)
	}

	rows, err := db.Query(`
		SELECT rowid, distance
		FROM vec_items
		WHERE sample_embedding MATCH ?
		  AND k = 10
	`, param)
	if err != nil {
		panic(err)
	}
	defer rows.Close()

	for rows.Next() {
		var rowid int64
		var distance float64
		if err := rows.Scan(&rowid, &distance); err != nil {
			panic(err)
		}
		fmt.Println(rowid, distance)
	}
	if err := rows.Err(); err != nil {
		panic(err)
	}
}
```

---

## 进阶说明

### SQLCipher 4.x 兼容性

注意：SQLCipher 4.x 与 3.x 默认不兼容。

如果你需要打开由旧版本创建的数据库，请参考：

- https://www.zetetic.net/sqlcipher/sqlcipher-api/#Migrating_Databases

### 检查数据库是否加密

可以使用导出的工具函数：

```go
isEnc := sqlite3.IsEncrypted("path/to/db")
```

---

## 常见问题（FAQ）

### 1) 编译报错：`cgo: C compiler not found`

你需要安装 C 编译器：

- macOS：Xcode Command Line Tools
- Linux：`gcc`/`clang`
- Windows：MinGW-w64 或 MSVC Build Tools

### 2) 如何调整 SQLCipher 参数/兼容性

你可以通过 DSN 传递 PRAGMA，例如：

- `_pragma_cipher_compatibility=3`

（具体 PRAGMA 以 SQLCipher 官方文档为准。）

---

## 开源协议

本项目代码受其原始组件的协议约束：

- go-sqlite3: MIT License（https://github.com/mattn/go-sqlite3）
- SQLCipher: BSD-style（https://github.com/sqlcipher/sqlcipher）
- sqlite-vec: MIT 或 Apache-2.0（https://github.com/asg017/sqlite-vec）
