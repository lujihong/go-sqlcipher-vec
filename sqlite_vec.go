package sqlite3

import (
	"encoding/binary"
	"fmt"
	"math"
)

// sqlite-vec subtype for float32 vectors
const SQLITE_VEC_ELEMENT_TYPE_FLOAT32 = 223

// Auto 注册 sqlite-vec 扩展到所有新连接。
// 我们在驱动的 init() 中已经自动调用了内部注册函数，
// 提供此方法是为了保持与官方 bindings 习惯一致。
func Auto() error {
	// 已经在 init() 中调用了 C._sqlite3_vec_init_auto()
	return nil
}

// SerializeFloat32 将 float32 切片序列化为 sqlite-vec 兼容的 compact BLOB 格式。
// 注意：sqlite-vec 的 compact format 在 BLOB 层面其实就是原始内存块，
// 但在插入时必须通过 SQLite 的 subtype 机制标记类型。
// 这里的实现生成原始小端序字节数组。
func SerializeFloat32(v []float32) ([]byte, error) {
	buf := make([]byte, len(v)*4)
	for i, f := range v {
		binary.LittleEndian.PutUint32(buf[i*4:], math.Float32bits(f))
	}
	return buf, nil
}

// VecBlob 包装了 BLOB 数据和它的 subtype。
// 用于在绑定参数时传递带有 subtype 的向量。
type VecBlob struct {
	Data    []byte
	Subtype int
}

// SerializeFloat32Param 返回一个带有正确 subtype 的 Value，
// 这样在插入 vec0 虚表时，扩展能正确识别这是一个 float32 向量。
func SerializeFloat32Param(v []float32) (VecBlob, error) {
	data, err := SerializeFloat32(v)
	if err != nil {
		return VecBlob{}, err
	}
	return VecBlob{
		Data:    data,
		Subtype: SQLITE_VEC_ELEMENT_TYPE_FLOAT32,
	}, nil
}

func (v VecBlob) String() string {
	return fmt.Sprintf("VecBlob(len=%d, subtype=%d)", len(v.Data), v.Subtype)
}




