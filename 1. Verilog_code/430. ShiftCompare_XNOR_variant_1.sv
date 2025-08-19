//SystemVerilog
module ShiftCompare_XNOR (
    input  wire        clk,            // 时钟信号
    input  wire        rst_n,          // 复位信号
    input  wire [2:0]  shift,          // 移位量
    input  wire [7:0]  base,           // 基础数据
    output wire [7:0]  res             // 结果输出
);
    // 定义流水线寄存器
    reg  [2:0]  shift_r1;
    reg  [7:0]  base_r1;
    reg  [7:0]  shifted_data_r1;
    
    // 第一级流水线 - 输入寄存
    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            shift_r1 <= 3'b0;
            base_r1  <= 8'b0;
        end else begin
            shift_r1 <= shift;
            base_r1  <= base;
        end
    end
    
    // 第二级流水线 - 移位操作
    wire [7:0] shifted_data;
    
    ShiftOperation u_shifter (
        .shift_amount  (shift_r1),
        .data_in       (base_r1),
        .data_out      (shifted_data)
    );
    
    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            shifted_data_r1 <= 8'b0;
        end else begin
            shifted_data_r1 <= shifted_data;
        end
    end
    
    // 第三级流水线 - 比较操作
    BitwiseComparator u_comparator (
        .data_a        (shifted_data_r1),
        .data_b        (base_r1),       // 使用寄存后的基础数据
        .result        (res)
    );
    
endmodule

// 优化的移位操作子模块
module ShiftOperation (
    input  wire [2:0]  shift_amount,
    input  wire [7:0]  data_in,
    output wire [7:0]  data_out
);
    // 分解移位操作，减少逻辑深度
    wire [7:0] shift_stage1;
    wire [7:0] shift_stage2;
    
    // 第一级移位 (0或1位)
    assign shift_stage1 = shift_amount[0] ? {data_in[6:0], 1'b0} : data_in;
    
    // 第二级移位 (0或2位)
    assign shift_stage2 = shift_amount[1] ? {shift_stage1[5:0], 2'b0} : shift_stage1;
    
    // 第三级移位 (0或4位)
    assign data_out = shift_amount[2] ? {shift_stage2[3:0], 4'b0} : shift_stage2;
    
endmodule

// 改进的比较器子模块
module BitwiseComparator (
    input  wire [7:0]  data_a,
    input  wire [7:0]  data_b,
    output wire [7:0]  result
);
    // 分解XNOR操作为两个步骤，便于综合工具优化
    wire [7:0] xor_result;
    
    // XOR操作
    assign xor_result = data_a ^ data_b;
    
    // 取反操作
    assign result = ~xor_result;
    
endmodule