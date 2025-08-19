//SystemVerilog
// IEEE 1364-2005 Verilog standard
module flagged_shift_reg #(parameter DEPTH = 8) (
    input wire clk, rst, push, pop,
    input wire data_in,
    output wire data_out,
    output wire empty, full
);

    // Register declarations
    reg [DEPTH-1:0] fifo;
    reg [$clog2(DEPTH):0] count;
    
    // Next state signals
    wire [DEPTH-1:0] next_fifo;
    wire [$clog2(DEPTH):0] next_count;
    
    // Two's complement based counter control signals
    wire [$clog2(DEPTH):0] count_inc, count_dec;
    wire [$clog2(DEPTH):0] neg_one;
    
    // Two's complement implementation for addition/subtraction
    assign neg_one = {($clog2(DEPTH)+1){1'b1}}; // -1 in two's complement
    assign count_inc = count + 1'b1;
    assign count_dec = count + neg_one; // Adding -1 using two's complement
    
    // Combinational logic for next state
    assign next_fifo = rst ? {DEPTH{1'b0}} :
                      (push && !full) ? {fifo[DEPTH-2:0], data_in} :
                      (pop && !empty) ? {1'b0, fifo[DEPTH-1:1]} :
                      fifo;
                      
    assign next_count = rst ? 0 :
                       (push && !full) ? count_inc :
                       (pop && !empty) ? count_dec :
                       count;
    
    // Sequential logic
    always @(posedge clk) begin
        fifo <= next_fifo;
        count <= next_count;
    end
    
    // Output assignments
    assign data_out = fifo[DEPTH-1];
    assign empty = (count == 0);
    assign full = (count == DEPTH);
    
endmodule