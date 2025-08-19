//SystemVerilog
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
    
    // Parallel prefix adder signals
    wire [31:0] timestamp_next;
    wire [31:0] carry_propagate;
    wire [31:0] carry_generate;
    wire [31:0] carry_out;
    
    // Generate and propagate signals
    assign carry_generate = 32'h1;
    assign carry_propagate = ~timestamp;
    
    // Parallel prefix tree
    genvar i;
    generate
        for (i = 0; i < 32; i = i + 1) begin : prefix_tree
            if (i == 0) begin
                assign carry_out[i] = carry_generate[i];
            end else begin
                assign carry_out[i] = carry_generate[i] | (carry_propagate[i] & carry_out[i-1]);
            end
        end
    endgenerate
    
    // Final sum calculation
    assign timestamp_next = timestamp ^ carry_out;
    
    always @(posedge clk) begin
        if (rst_sync) begin
            wr_ptr <= 0;
            timestamp <= 0;
        end else begin
            timestamp <= timestamp_next;
            if (ts_write) begin
                ring_buff[wr_ptr] <= {timestamp, data_in};
                wr_ptr <= (wr_ptr == BUFF_DEPTH-1) ? 0 : wr_ptr + 1;
            end
        end
    end
    
    assign data_out = ring_buff[wr_ptr];
endmodule