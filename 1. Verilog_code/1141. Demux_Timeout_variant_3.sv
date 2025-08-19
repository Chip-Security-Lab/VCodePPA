//SystemVerilog IEEE 1364-2005
module Demux_Timeout #(parameter DW=8, TIMEOUT=100) (
    input clk, rst,
    input valid,
    input [DW-1:0] data_in,
    input [3:0] addr,
    output reg [15:0][DW-1:0] data_out,
    output reg timeout
);
    // 使用向下计数而非向上计数
    reg [7:0] down_counter;
    wire [7:0] next_count;
    wire borrow;
    
    // 借位减法器实现
    assign {borrow, next_count} = down_counter - 8'd1;
    
    // 计数器控制逻辑
    always @(posedge clk) begin
        if (rst) begin
            down_counter <= TIMEOUT;
        end else if (valid) begin
            down_counter <= TIMEOUT;
        end else begin
            // 使用借位减法替代原来的加法逻辑
            down_counter <= (down_counter > 0) ? next_count : 8'd0;
        end
    end
    
    // 超时标志控制逻辑
    always @(posedge clk) begin
        if (rst) begin
            timeout <= 1'b0;
        end else if (valid) begin
            timeout <= 1'b0;
        end else begin
            timeout <= (down_counter == 8'd1);
        end
    end
    
    // 数据输出控制逻辑
    always @(posedge clk) begin
        if (rst) begin
            data_out <= {16{1'b0}};
        end else if (valid) begin
            data_out[addr] <= data_in;
        end else if (timeout) begin
            data_out <= {16{1'b0}};
        end
    end
endmodule