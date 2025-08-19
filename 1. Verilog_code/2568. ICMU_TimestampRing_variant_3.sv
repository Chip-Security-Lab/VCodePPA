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

    // Memory array with registered output
    reg [DW-1:0] ring_buff [0:BUFF_DEPTH-1];
    reg [DW-1:0] data_out_reg;
    
    // Control registers
    reg [4:0] wr_ptr;
    reg [31:0] timestamp;
    
    // Optimized write pointer logic
    wire [4:0] wr_ptr_next = (wr_ptr == BUFF_DEPTH-1) ? 5'd0 : wr_ptr + 5'd1;
    
    // Optimized timestamp concatenation
    wire [DW-1:0] write_data = {timestamp, data_in};
    
    // Main control logic
    always @(posedge clk) begin
        if (rst_sync) begin
            wr_ptr <= 5'd0;
            timestamp <= 32'd0;
            data_out_reg <= {DW{1'b0}};
        end else begin
            timestamp <= timestamp + 32'd1;
            
            if (ts_write) begin
                ring_buff[wr_ptr] <= write_data;
                wr_ptr <= wr_ptr_next;
            end
            
            data_out_reg <= ring_buff[wr_ptr];
        end
    end
    
    assign data_out = data_out_reg;

endmodule