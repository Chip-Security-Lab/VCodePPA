//SystemVerilog
//IEEE 1364-2005 Verilog标准
module Cond_NAND #(
    parameter DATA_WIDTH = 4
)(
    input                     clk,      // 时钟信号
    input                     rst_n,    // 复位信号
    input                     sel,
    input  [DATA_WIDTH-1:0]   mask,
    input  [DATA_WIDTH-1:0]   data_in,
    output [DATA_WIDTH-1:0]   data_out
);
    // 内部信号声明
    wire [DATA_WIDTH-1:0] masked_data;
    wire [DATA_WIDTH-1:0] nand_result;
    
    // 数据处理单元
    DataProcessor #(
        .WIDTH(DATA_WIDTH)
    ) data_proc_unit (
        .clk        (clk),
        .rst_n      (rst_n),
        .data_in    (data_in),
        .mask       (mask),
        .masked_data(masked_data),
        .nand_result(nand_result)
    );
    
    // 输出选择单元
    OutputControl #(
        .WIDTH(DATA_WIDTH)
    ) output_ctrl_unit (
        .clk        (clk),
        .rst_n      (rst_n),
        .sel        (sel),
        .data_in    (data_in),
        .nand_result(nand_result),
        .data_out   (data_out)
    );
    
endmodule

// 数据处理单元：包含掩码和NAND操作
module DataProcessor #(
    parameter WIDTH = 4
)(
    input                   clk,
    input                   rst_n,
    input  [WIDTH-1:0]      data_in,
    input  [WIDTH-1:0]      mask,
    output reg [WIDTH-1:0]  masked_data,
    output reg [WIDTH-1:0]  nand_result
);
    // 掩码操作
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            masked_data <= {WIDTH{1'b0}};
        end else begin
            masked_data <= data_in & mask;
        end
    end
    
    // NAND操作
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            nand_result <= {WIDTH{1'b1}};
        end else begin
            nand_result <= ~masked_data;
        end
    end
endmodule

// 输出控制单元：根据选择信号选择输出
module OutputControl #(
    parameter WIDTH = 4
)(
    input                   clk,
    input                   rst_n,
    input                   sel,
    input  [WIDTH-1:0]      data_in,
    input  [WIDTH-1:0]      nand_result,
    output reg [WIDTH-1:0]  data_out
);
    // 输出选择器
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_out <= {WIDTH{1'b0}};
        end else begin
            data_out <= sel ? nand_result : data_in;
        end
    end
endmodule