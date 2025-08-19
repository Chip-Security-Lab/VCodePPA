//SystemVerilog
// 顶层模块
module param_buffer #(
    parameter DATA_WIDTH = 16
)(
    input wire clk,
    input wire [DATA_WIDTH-1:0] data_in,
    input wire load,
    output wire [DATA_WIDTH-1:0] data_out
);
    // 内部连接信号
    wire [DATA_WIDTH-1:0] data_in_registered;
    wire load_registered;
    
    // 实例化输入寄存子模块
    input_register #(
        .DATA_WIDTH(DATA_WIDTH)
    ) u_input_register (
        .clk(clk),
        .data_in(data_in),
        .load(load),
        .data_out(data_in_registered),
        .load_out(load_registered)
    );
    
    // 实例化状态更新子模块
    state_update #(
        .DATA_WIDTH(DATA_WIDTH)
    ) u_state_update (
        .clk(clk),
        .data_in(data_in_registered),
        .load(load_registered),
        .data_out(data_out)
    );
endmodule

// 输入寄存子模块
module input_register #(
    parameter DATA_WIDTH = 16
)(
    input wire clk,
    input wire [DATA_WIDTH-1:0] data_in,
    input wire load,
    output reg [DATA_WIDTH-1:0] data_out,
    output reg load_out
);
    // 对输入进行寄存
    always @(posedge clk) begin
        data_out <= data_in;
        load_out <= load;
    end
endmodule

// 状态更新子模块
module state_update #(
    parameter DATA_WIDTH = 16
)(
    input wire clk,
    input wire [DATA_WIDTH-1:0] data_in,
    input wire load,
    output reg [DATA_WIDTH-1:0] data_out
);
    // 根据控制信号更新输出状态
    always @(posedge clk) begin
        if (load)
            data_out <= data_in;
    end
endmodule