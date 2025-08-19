//SystemVerilog
module bidir_shift_reg(
    input wire clock, clear,
    input wire [7:0] p_data,
    input wire load, shift, dir, s_in,
    output wire [7:0] q
);
    // 内部连接信号
    wire [1:0] operation;
    wire [7:0] shift_result;
    wire [7:0] reg_data;
    
    // 子模块实例化
    control_unit ctrl_inst (
        .load(load),
        .shift(shift),
        .operation(operation)
    );
    
    shift_unit shift_inst (
        .q_current(reg_data),
        .s_in(s_in),
        .dir(dir),
        .shift_result(shift_result)
    );
    
    register_unit reg_inst (
        .clock(clock),
        .clear(clear),
        .operation(operation),
        .p_data(p_data),
        .shift_result(shift_result),
        .q(reg_data)
    );
    
    // 输出赋值
    assign q = reg_data;
    
endmodule

// 控制单元：负责生成操作控制信号
module control_unit(
    input wire load,
    input wire shift,
    output wire [1:0] operation
);
    // 生成控制信号
    assign operation = {load, shift & ~load};
endmodule

// 移位单元：处理左移和右移逻辑
module shift_unit(
    input wire [7:0] q_current,
    input wire s_in,
    input wire dir,
    output wire [7:0] shift_result
);
    // 移位操作逻辑
    wire [7:0] right_shift = {s_in, q_current[7:1]};
    wire [7:0] left_shift = {q_current[6:0], s_in};
    
    // 根据方向选择移位结果
    assign shift_result = dir ? right_shift : left_shift;
endmodule

// 寄存器单元：存储数据并处理时序逻辑
module register_unit(
    input wire clock,
    input wire clear,
    input wire [1:0] operation,
    input wire [7:0] p_data,
    input wire [7:0] shift_result,
    output reg [7:0] q
);
    // 寄存器逻辑，处理清零、加载和移位操作
    always @(posedge clock) begin
        if (clear)
            q <= 8'b0;
        else begin
            case(operation)
                2'b10:   q <= p_data;      // Load operation
                2'b01:   q <= shift_result; // Shift operation
                default: q <= q;           // Hold value
            endcase
        end
    end
endmodule