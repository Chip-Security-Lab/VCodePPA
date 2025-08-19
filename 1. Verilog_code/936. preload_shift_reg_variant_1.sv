//SystemVerilog
module preload_shift_reg (
    input clk, load,
    input [3:0] shift,
    input [15:0] load_data,
    output reg [15:0] shifted
);
    // 存储寄存器，用于保存加载的数据
    reg [15:0] storage;
    
    // 中间信号，用于先行借位减法运算
    wire [15:0] left_shifted, right_shifted;
    wire [4:0] inverse_shift;
    
    // 先行借位减法器计算逻辑
    assign inverse_shift = 16 - {1'b0, shift};
    
    // 使用参数化方式实现左移和右移
    generate_shifter left_shifter (
        .data(storage),
        .shift_amount(shift),
        .shifted_data(left_shifted)
    );
    
    generate_shifter right_shifter (
        .data(storage),
        .shift_amount(inverse_shift[3:0]),
        .shifted_data(right_shifted)
    );
    
    // 第一个always块：处理数据加载逻辑
    always @(posedge clk) begin
        if (load) 
            storage <= load_data;
    end
    
    // 第二个always块：处理移位操作逻辑
    always @(posedge clk) begin
        if (!load)
            shifted <= left_shifted | right_shifted;
    end
endmodule

// 参数化移位器模块
module generate_shifter (
    input [15:0] data,
    input [3:0] shift_amount,
    output [15:0] shifted_data
);
    // 内部信号
    wire [15:0] shift_stage [4:0];
    wire [15:0] borrow_stage [3:0];
    
    // 初始数据
    assign shift_stage[0] = data;
    
    // 4级先行借位移位网络
    genvar i;
    generate
        for (i = 0; i < 4; i = i + 1) begin: shift_stage_gen
            // 计算借位信号
            assign borrow_stage[i] = shift_amount[i] ? {shift_stage[i][15-2**i:0], {(2**i){1'b0}}} : shift_stage[i];
            
            // 计算下一级移位结果
            assign shift_stage[i+1] = borrow_stage[i];
        end
    endgenerate
    
    // 最终结果
    assign shifted_data = shift_stage[4];
endmodule