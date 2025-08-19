//SystemVerilog
module pipelined_borrow_subtractor #(parameter WIDTH=8) (
    input clk,
    input en,
    input [WIDTH-1:0] minuend,     // 被减数
    input [WIDTH-1:0] subtrahend,  // 减数
    output [WIDTH-1:0] difference, // 差
    output borrow_out              // 最终借位
);
    wire [WIDTH-1:0] diff_result;
    wire borrow_result;
    
    // 实例化优化后的借位减法器
    borrow_subtractor #(
        .WIDTH(WIDTH)
    ) sub_unit (
        .minuend(minuend),
        .subtrahend(subtrahend),
        .difference(diff_result),
        .borrow_out(borrow_result)
    );
    
    // 使用寄存器存储减法器输出
    pl_reg_bitslice #(
        .W(WIDTH)
    ) diff_reg (
        .clk(clk),
        .en(en),
        .data_in(diff_result),
        .data_out(difference)
    );
    
    // 使用寄存器存储借位标志
    pl_reg_bitslice #(
        .W(1)
    ) borrow_reg (
        .clk(clk),
        .en(en),
        .data_in(borrow_result),
        .data_out(borrow_out)
    );
    
endmodule

module pl_reg_bitslice #(parameter W=8) (
    input clk, en,
    input [W-1:0] data_in,
    output [W-1:0] data_out
);
    // 将单个always块拆分为每一位的独立寄存器
    reg [W-1:0] data_out_reg;
    
    // 时钟使能控制逻辑
    always @(posedge clk) begin
        if (en) data_out_reg <= data_in;
    end
    
    assign data_out = data_out_reg;
endmodule

module borrow_subtractor #(parameter WIDTH=8) (
    input [WIDTH-1:0] minuend,     // 被减数
    input [WIDTH-1:0] subtrahend,  // 减数
    output [WIDTH-1:0] difference, // 差
    output borrow_out              // 最终借位输出
);
    // 拆分为多个逻辑单元处理不同功能
    wire [WIDTH-1:0] xor_result;
    wire [WIDTH-1:0] gen_borrow;   // 直接生成借位
    wire [WIDTH-1:0] prop_borrow;  // 传播前一位的借位
    wire [WIDTH:0] borrow;         // 借位信号链
    
    // 初始借位
    assign borrow[0] = 1'b0;
    
    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin: gen_borrow_sub
            // 阶段1: XOR预计算单元
            assign xor_result[i] = minuend[i] ^ subtrahend[i];
            
            // 阶段2: 借位生成器
            assign gen_borrow[i] = ~minuend[i] & subtrahend[i];
            
            // 阶段3: 借位传播器
            assign prop_borrow[i] = ~minuend[i] | subtrahend[i];
            
            // 阶段4: 借位计算单元
            assign borrow[i+1] = gen_borrow[i] | (borrow[i] & prop_borrow[i]);
            
            // 阶段5: 差值计算单元
            assign difference[i] = xor_result[i] ^ borrow[i];
        end
    endgenerate
    
    // 最终借位输出
    assign borrow_out = borrow[WIDTH];
    
endmodule