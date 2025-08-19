//SystemVerilog
// IEEE 1364-2005 Verilog
module HammingShift #(parameter DATA_BITS=4) (
    input wire clk,
    input wire sin,
    output reg [DATA_BITS+2:0] encoded // 4数据位 + 3校验位
);
    // 输入管道寄存
    reg sin_stage1;
    
    // 数据移位寄存器
    reg [DATA_BITS-1:0] data_shift;
    
    // 数据寄存管道 - 流水线第二级
    reg [DATA_BITS-1:0] data_stage2;
    
    // 校验位计算 - 基于暂存数据计算
    wire [2:0] parity_bits;
    assign parity_bits[0] = data_stage2[1] ^ data_stage2[2] ^ data_stage2[3]; // p0
    assign parity_bits[1] = data_stage2[0] ^ data_stage2[2] ^ data_stage2[3]; // p1
    assign parity_bits[2] = data_stage2[0] ^ data_stage2[1] ^ data_stage2[3]; // p2
    
    // 主数据通路 - 三级流水线
    always @(posedge clk) begin
        // 阶段1: 输入寄存管道
        sin_stage1 <= sin;
        
        // 阶段1: 数据位移位寄存
        data_shift <= {data_shift[DATA_BITS-2:0], sin_stage1};
        
        // 阶段2: 数据暂存准备校验计算
        data_stage2 <= data_shift;
        
        // 阶段3: 编码输出 - 组合校验位与数据位
        encoded <= {parity_bits, data_stage2};
    end
endmodule