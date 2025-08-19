module ICMU_TimestampRing #(
    parameter DW = 64,
    parameter BUFF_DEPTH = 16
)(
    input clk,
    input rst_sync,
    input ts_write,
    input [DW-2:0] data_in, // [63:1]
    output [DW-1:0] data_out
);
    reg [DW-1:0] ring_buff [0:BUFF_DEPTH-1];
    reg [4:0] wr_ptr;
    reg [31:0] timestamp;
    
    always @(posedge clk) begin
        if (rst_sync) begin
            wr_ptr <= 0;
            timestamp <= 0;
        end else begin
            timestamp <= timestamp + 1;
            if (ts_write) begin
                ring_buff[wr_ptr] <= {timestamp, data_in};
                wr_ptr <= (wr_ptr == BUFF_DEPTH-1) ? 0 : wr_ptr + 1;
            end
        end
    end
    
    assign data_out = ring_buff[wr_ptr];
endmodule
