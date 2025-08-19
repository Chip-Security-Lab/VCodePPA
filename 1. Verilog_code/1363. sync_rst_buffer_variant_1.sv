//SystemVerilog
// 顶层模块
module sync_rst_buffer (
    input  wire        clk,
    input  wire        rst,
    input  wire [31:0] data_in,
    input  wire        load,
    output wire [31:0] data_out
);
    // 内部连线
    wire        load_buffered;
    wire [31:0] data_buffered;
    
    // 实例化输入缓冲子模块
    input_buffer input_buffer_inst (
        .clk          (clk),
        .load_in      (load),
        .data_in      (data_in),
        .load_out     (load_buffered),
        .data_out     (data_buffered)
    );
    
    // 实例化输出寄存器子模块
    output_register output_register_inst (
        .clk          (clk),
        .rst          (rst),
        .load         (load_buffered),
        .data_in      (data_buffered),
        .data_out     (data_out)
    );
endmodule

// 输入缓冲子模块 - 负责缓存输入信号
module input_buffer (
    input  wire        clk,
    input  wire        load_in,
    input  wire [31:0] data_in,
    output reg         load_out,
    output reg  [31:0] data_out
);
    // 将寄存器前移到输入端，捕获输入信号
    always @(posedge clk) begin
        load_out <= load_in;
        data_out <= data_in;
    end
endmodule

// 输出寄存器子模块 - 负责在复位或加载时更新输出
module output_register (
    input  wire        clk,
    input  wire        rst,
    input  wire        load,
    input  wire [31:0] data_in,
    output reg  [31:0] data_out
);
    // 输出寄存器逻辑
    always @(posedge clk) begin
        if (rst)
            data_out <= 32'b0;
        else if (load)
            data_out <= data_in;
    end
endmodule