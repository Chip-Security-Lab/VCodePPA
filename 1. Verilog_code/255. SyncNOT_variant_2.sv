//SystemVerilog
// 顶层模块
module SyncNOT(
    input clk,
    input rst_n,
    input [15:0] async_in,
    output [15:0] synced_not
);
    // 内部连线
    wire [15:0] sampled_data;
    wire [15:0] inverted_data;
    
    // 实例化输入同步子模块
    InputSampler input_stage (
        .clk(clk),
        .rst_n(rst_n),
        .async_in(async_in),
        .sampled_out(sampled_data)
    );
    
    // 实例化数据处理子模块
    DataInverter processing_stage (
        .clk(clk),
        .rst_n(rst_n),
        .data_in(sampled_data),
        .data_out(inverted_data)
    );
    
    // 实例化输出寄存器子模块
    OutputRegister output_stage (
        .clk(clk),
        .rst_n(rst_n),
        .data_in(inverted_data),
        .data_out(synced_not)
    );
endmodule

// 输入采样子模块
module InputSampler #(
    parameter WIDTH = 16
)(
    input clk,
    input rst_n,
    input [WIDTH-1:0] async_in,
    output reg [WIDTH-1:0] sampled_out
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sampled_out <= {WIDTH{1'b0}};
        end else begin
            sampled_out <= async_in;
        end
    end
endmodule

// 数据处理子模块
module DataInverter #(
    parameter WIDTH = 16
)(
    input clk,
    input rst_n,
    input [WIDTH-1:0] data_in,
    output reg [WIDTH-1:0] data_out
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_out <= {WIDTH{1'b0}};
        end else begin
            data_out <= ~data_in;
        end
    end
endmodule

// 输出寄存器子模块
module OutputRegister #(
    parameter WIDTH = 16
)(
    input clk,
    input rst_n,
    input [WIDTH-1:0] data_in,
    output reg [WIDTH-1:0] data_out
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_out <= {WIDTH{1'b0}};
        end else begin
            data_out <= data_in;
        end
    end
endmodule