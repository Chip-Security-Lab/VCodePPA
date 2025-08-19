//SystemVerilog
// 顶层模块
module BusInverter(
    input [63:0] bus_input,
    output [63:0] inverted_bus
);
    // 将64位总线分为8个8位子块，以实现更好的布局和时序
    wire [7:0] inverted_bus_seg[0:7];
    
    // 实例化8个8位子模块
    genvar j;
    generate
        for (j = 0; j < 8; j = j + 1) begin : SEGMENT_INVERTER
            ByteInverter u_byte_inverter (
                .byte_in(bus_input[(j*8)+7:(j*8)]),
                .byte_out(inverted_bus_seg[j])
            );
        end
    endgenerate
    
    // 重组输出总线
    genvar k;
    generate
        for (k = 0; k < 8; k = k + 1) begin : OUTPUT_ASSEMBLE
            assign inverted_bus[(k*8)+7:(k*8)] = inverted_bus_seg[k];
        end
    endgenerate
endmodule

// 8位字节反相器子模块 (添加跳跃进位加法器)
module ByteInverter(
    input [7:0] byte_in,
    output [7:0] byte_out
);
    // 内部加法器信号
    wire [7:0] add_result;
    
    // 实例化跳跃进位加法器
    SkipCarryAdder #(.WIDTH(8)) byte_adder (
        .a(byte_in),
        .b(8'h01),  // 加1操作
        .sum(add_result)
    );
    
    // 反相操作 + 加法操作的组合
    InverterCell #(.WIDTH(8)) inverter (
        .data_in(add_result),  // 先加法后反相
        .data_out(byte_out)
    );
endmodule

// 可参数化的数据反相器基本单元
module InverterCell #(
    parameter WIDTH = 4
)(
    input [WIDTH-1:0] data_in,
    output [WIDTH-1:0] data_out
);
    // 基本反相逻辑，使用for循环进行参数化反相操作
    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : BIT_INV
            // 添加非缓冲器以改善驱动能力和时序
            assign data_out[i] = ~data_in[i];
        end
    endgenerate
endmodule

// 跳跃进位加法器 (64位实现，分成8个跳跃块)
module SkipCarryAdder #(
    parameter WIDTH = 64,
    parameter BLOCK_SIZE = 8
)(
    input [WIDTH-1:0] a,
    input [WIDTH-1:0] b,
    output [WIDTH-1:0] sum
);
    localparam NUM_BLOCKS = WIDTH / BLOCK_SIZE;
    
    // 内部进位信号
    wire [NUM_BLOCKS:0] block_carry;
    wire [NUM_BLOCKS-1:0] block_propagate;
    wire [WIDTH-1:0] internal_sum;
    
    // 初始进位为0
    assign block_carry[0] = 1'b0;
    
    genvar i, j;
    generate
        // 实例化每个块加法器
        for (i = 0; i < NUM_BLOCKS; i = i + 1) begin : BLOCK_ADDERS
            wire [BLOCK_SIZE-1:0] block_a, block_b, block_sum;
            wire [BLOCK_SIZE:0] block_internal_carry;
            wire block_p; // 传播信号
            
            // 提取当前块的输入
            assign block_a = a[(i*BLOCK_SIZE)+:BLOCK_SIZE];
            assign block_b = b[(i*BLOCK_SIZE)+:BLOCK_SIZE];
            
            // 块内部的进位链
            assign block_internal_carry[0] = block_carry[i];
            
            // 块内部的全加器
            for (j = 0; j < BLOCK_SIZE; j = j + 1) begin : BIT_ADDERS
                wire p, g; // 传播和生成信号
                
                // 计算传播和生成信号
                assign p = block_a[j] ^ block_b[j];
                assign g = block_a[j] & block_b[j];
                
                // 计算本位进位和和
                assign block_internal_carry[j+1] = g | (p & block_internal_carry[j]);
                assign block_sum[j] = p ^ block_internal_carry[j];
            end
            
            // 计算整个块的传播信号
            wire block_propagate_temp;
            assign block_propagate_temp = &(block_a | block_b); // 如果所有位都可以传播
            assign block_propagate[i] = block_propagate_temp;
            
            // 跳跃进位逻辑
            assign block_carry[i+1] = block_propagate[i] ? block_carry[i] : block_internal_carry[BLOCK_SIZE];
            
            // 连接块输出到总和
            assign internal_sum[(i*BLOCK_SIZE)+:BLOCK_SIZE] = block_sum;
        end
    endgenerate
    
    // 最终结果
    assign sum = internal_sum;
endmodule