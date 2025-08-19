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
    // 内部连线
    wire [DATA_WIDTH-1:0] registered_data;
    wire registered_load;
    
    // 实例化数据寄存子模块
    data_register #(
        .DATA_WIDTH(DATA_WIDTH)
    ) data_reg_inst (
        .clk(clk),
        .data_in(data_in),
        .data_out(registered_data)
    );
    
    // 实例化控制信号寄存子模块
    control_register ctrl_reg_inst (
        .clk(clk),
        .load_in(load),
        .load_out(registered_load)
    );
    
    // 实例化输出多路复用器子模块
    output_mux #(
        .DATA_WIDTH(DATA_WIDTH)
    ) out_mux_inst (
        .data_in(registered_data),
        .load_sel(registered_load),
        .data_out(data_out)
    );
endmodule

// 数据寄存子模块
module data_register #(
    parameter DATA_WIDTH = 16
)(
    input wire clk,
    input wire [DATA_WIDTH-1:0] data_in,
    output reg [DATA_WIDTH-1:0] data_out
);
    always @(posedge clk) begin
        data_out <= data_in;
    end
endmodule

// 控制信号寄存子模块
module control_register (
    input wire clk,
    input wire load_in,
    output reg load_out
);
    always @(posedge clk) begin
        load_out <= load_in;
    end
endmodule

// 输出多路复用器子模块
module output_mux #(
    parameter DATA_WIDTH = 16
)(
    input wire [DATA_WIDTH-1:0] data_in,
    input wire load_sel,
    output wire [DATA_WIDTH-1:0] data_out
);
    assign data_out = load_sel ? data_in : data_out;
endmodule