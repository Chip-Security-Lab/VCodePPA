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
    reg [DW-1:0] data_out_reg;
    reg [DW-1:0] next_data;
    reg [4:0] next_ptr;
    reg [31:0] next_timestamp;
    
    // Combinational logic for next state
    always @(*) begin
        next_timestamp = timestamp + 1;
        if (ts_write) begin
            next_data = {next_timestamp, data_in};
            next_ptr = (wr_ptr == BUFF_DEPTH-1) ? 0 : wr_ptr + 1;
        end else begin
            next_data = ring_buff[wr_ptr];
            next_ptr = wr_ptr;
        end
    end
    
    // Sequential logic
    always @(posedge clk) begin
        if (rst_sync) begin
            wr_ptr <= 0;
            timestamp <= 0;
            data_out_reg <= 0;
        end else begin
            timestamp <= next_timestamp;
            wr_ptr <= next_ptr;
            if (ts_write) begin
                ring_buff[wr_ptr] <= next_data;
            end
            data_out_reg <= ring_buff[wr_ptr];
        end
    end
    
    assign data_out = data_out_reg;
endmodule