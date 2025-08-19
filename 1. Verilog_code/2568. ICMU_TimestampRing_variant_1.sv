//SystemVerilog
module ICMU_TimestampRing #(
    parameter DW = 64,
    parameter BUFF_DEPTH = 16
)(
    input clk,
    input rst_sync,
    input ts_write,
    input [DW-2:0] data_in,
    output [DW-1:0] data_out
);
    reg [DW-1:0] ring_buff [0:BUFF_DEPTH-1];
    reg [4:0] wr_ptr;
    reg [31:0] timestamp;
    wire [4:0] next_wr_ptr;
    wire [DW-1:0] data_to_write;
    
    // Pre-compute next write pointer and data to write
    assign next_wr_ptr = (wr_ptr + 1) & (BUFF_DEPTH-1);
    assign data_to_write = {timestamp, data_in};
    
    // Split timestamp increment and write logic for better timing
    always @(posedge clk) begin
        if (rst_sync) begin
            wr_ptr <= 0;
            timestamp <= 0;
        end else begin
            timestamp <= timestamp + 1;
        end
    end
    
    // Separate write logic to reduce critical path
    always @(posedge clk) begin
        if (!rst_sync && ts_write) begin
            ring_buff[wr_ptr] <= data_to_write;
            wr_ptr <= next_wr_ptr;
        end
    end
    
    assign data_out = ring_buff[wr_ptr];
endmodule