//SystemVerilog
module Demux_Timeout #(parameter DW=8, TIMEOUT=100) (
    input clk, rst,
    input valid,
    input [DW-1:0] data_in,
    input [3:0] addr,
    output reg [15:0][DW-1:0] data_out,
    output reg timeout
);
    reg [7:0] counter;
    reg [7:0] counter_next;
    
    // 优化的比较逻辑，使用直接比较替代减法实现
    always @(*) begin
        if (counter < TIMEOUT - 1'b1) begin
            counter_next = counter + 1'b1;
        end else begin
            counter_next = TIMEOUT;
        end
    end
    
    always @(posedge clk) begin
        if (rst) begin
            counter <= 8'd0;
            data_out <= 'd0;
            timeout <= 1'b0;
        end else if (valid) begin
            data_out[addr] <= data_in;
            counter <= 8'd0;
            timeout <= 1'b0;
        end else begin
            counter <= counter_next;
            timeout <= (counter >= TIMEOUT - 1'b1);
            if(timeout) data_out <= 'd0;
        end
    end
endmodule