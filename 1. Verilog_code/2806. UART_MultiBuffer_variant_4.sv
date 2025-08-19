//SystemVerilog
module UART_MultiBuffer #(
    parameter BUFFER_LEVEL = 4
)(
    input wire clk,
    input wire [7:0] rx_data,
    input wire rx_valid,
    output wire [7:0] buffer_occupancy,
    input wire buffer_flush
);

// 前向寄存器重定时：将输入端寄存器移至组合逻辑后
reg [7:0] data_pipe [0:BUFFER_LEVEL-1];
reg [BUFFER_LEVEL-1:0] valid_pipe;
integer i;

// 前级组合逻辑输出
wire [7:0] next_data_pipe [0:BUFFER_LEVEL-1];
wire [BUFFER_LEVEL-1:0] next_valid_pipe;

// 组合逻辑部分：数据和有效位前传
assign next_data_pipe[0] = rx_data;
generate
    genvar j;
    for (j = 1; j < BUFFER_LEVEL; j = j + 1) begin : DATA_PIPE_GEN
        assign next_data_pipe[j] = data_pipe[j-1];
    end
endgenerate

assign next_valid_pipe = {valid_pipe[BUFFER_LEVEL-2:0], rx_valid};

// 时序寄存器移至组合逻辑后
always @(posedge clk) begin
    if (buffer_flush) begin
        for (i = 0; i < BUFFER_LEVEL; i = i + 1) begin
            data_pipe[i] <= 8'b0;
        end
        valid_pipe <= {BUFFER_LEVEL{1'b0}};
    end else begin
        for (i = 0; i < BUFFER_LEVEL; i = i + 1) begin
            data_pipe[i] <= next_data_pipe[i];
        end
        valid_pipe <= next_valid_pipe;
    end
end

// 优化的水位检测：采用并行计数方式
function [3:0] count_ones;
    input [BUFFER_LEVEL-1:0] vec;
    integer idx;
    begin
        count_ones = 0;
        for (idx = 0; idx < BUFFER_LEVEL; idx = idx + 1) begin
            count_ones = count_ones + vec[idx];
        end
    end
endfunction

wire [3:0] occupancy_level;
assign occupancy_level = count_ones(valid_pipe);

assign buffer_occupancy = {4'b0, occupancy_level};

endmodule