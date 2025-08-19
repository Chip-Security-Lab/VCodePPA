//SystemVerilog
module ITRC_FIFO_Buffered #(
    parameter DW = 8,
    parameter DEPTH = 4
)(
    input clk,
    input rst_n,
    input [DW-1:0] int_in,
    input int_valid,
    output [DW-1:0] int_out,
    output empty
);
    localparam PTR_WIDTH = $clog2(DEPTH);
    reg [DW-1:0] fifo [0:DEPTH-1];
    reg [PTR_WIDTH-1:0] w_ptr, r_ptr;
    reg [PTR_WIDTH:0] count;
    
    // Look-ahead carry subtractor logic
    wire [PTR_WIDTH:0] count_next;
    wire [PTR_WIDTH:0] count_inc = {1'b0, w_ptr} + 1'b1;
    wire [PTR_WIDTH:0] count_dec;
    
    // Generate look-ahead carry signals
    wire [PTR_WIDTH:0] borrow;
    wire [PTR_WIDTH:0] count_temp;
    
    assign borrow[0] = 1'b0;
    genvar i;
    generate
        for (i = 0; i <= PTR_WIDTH; i = i + 1) begin : gen_sub
            assign count_temp[i] = count[i] ^ 1'b1 ^ borrow[i];
            if (i < PTR_WIDTH) begin
                assign borrow[i+1] = (~count[i] & 1'b1) | (~count[i] & borrow[i]) | (1'b1 & borrow[i]);
            end
        end
    endgenerate
    assign count_dec = count_temp;
    
    assign count_next = (int_valid && count < DEPTH) ? count_inc :
                       (!empty && !int_valid) ? count_dec : count;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            w_ptr <= 0;
            r_ptr <= 0;
            count <= 0;
        end
        else begin
            if (int_valid && count < DEPTH) begin
                fifo[w_ptr] <= int_in;
                w_ptr <= w_ptr + 1'b1;
            end
            if (!empty && !int_valid) begin
                r_ptr <= r_ptr + 1'b1;
            end
            count <= count_next;
        end
    end
    
    assign int_out = fifo[r_ptr];
    assign empty = (count == 0);
endmodule