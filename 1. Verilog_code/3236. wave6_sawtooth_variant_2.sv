//SystemVerilog
// 顶层模块: 锯齿波发生器
module wave6_sawtooth #(
    parameter WIDTH = 8
)(
    input  wire             clk,
    input  wire             rst,
    output wire [WIDTH-1:0] wave_out
);
    // 内部信号
    wire [WIDTH-1:0] next_value;
    wire [WIDTH-1:0] current_value;
    
    // 子模块实例化
    counter_logic #(
        .WIDTH(WIDTH)
    ) counter_inst (
        .current_value(current_value),
        .next_value(next_value)
    );
    
    register_unit #(
        .WIDTH(WIDTH)
    ) register_inst (
        .clk(clk),
        .rst(rst),
        .data_in(next_value),
        .data_out(current_value)
    );
    
    // 输出赋值
    assign wave_out = current_value;
    
endmodule

// 计数逻辑子模块
module counter_logic #(
    parameter WIDTH = 8
)(
    input  wire [WIDTH-1:0] current_value,
    output wire [WIDTH-1:0] next_value
);
    // 简单的递增逻辑
    assign next_value = current_value + 1'b1;
endmodule

// 寄存器单元子模块
module register_unit #(
    parameter WIDTH = 8
)(
    input  wire             clk,
    input  wire             rst,
    input  wire [WIDTH-1:0] data_in,
    output reg  [WIDTH-1:0] data_out
);
    // 时序逻辑
    always @(posedge clk or posedge rst) begin
        if (rst) 
            data_out <= {WIDTH{1'b0}};
        else
            data_out <= data_in;
    end
endmodule