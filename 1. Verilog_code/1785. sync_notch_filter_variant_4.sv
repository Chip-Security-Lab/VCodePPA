//SystemVerilog
module sync_notch_filter #(
    parameter DW = 10
)(
    input clk, rst_n,
    input [DW-1:0] x_in,
    input [DW-1:0] notch_freq,
    input [DW-1:0] q_factor,
    output reg [DW-1:0] y_out
);
    reg [DW-1:0] x1, x2, y1, y2;
    wire [DW-1:0] b0, b1, b2, a1, a2;
    wire [2*DW-1:0] sum_b_terms, sum_a_terms;
    wire [2*DW-1:0] acc;
    wire [2*DW-1:0] a_term_inv;
    wire borrow;
    
    // Coefficient calculation would be external in practice
    assign b0 = q_factor;
    assign b1 = -{DW{1'b1}};  // -1 in 2's complement
    assign b2 = q_factor;
    assign a1 = -{DW{1'b1}};  // -1 in 2's complement
    assign a2 = (q_factor * 2) - (notch_freq >> 2);
    
    // Compute positive and negative terms separately
    assign sum_b_terms = (b0*x_in + b1*x1 + b2*x2);
    assign sum_a_terms = (a1*y1 + a2*y2);
    
    // Conditional sum subtraction for a_terms
    assign a_term_inv = ~sum_a_terms + 1'b1;
    assign {borrow, acc} = {1'b0, sum_b_terms} + {1'b0, a_term_inv};
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            x1 <= 0; x2 <= 0; y1 <= 0; y2 <= 0; y_out <= 0;
        end else begin
            x2 <= x1; x1 <= x_in;
            y2 <= y1; y1 <= acc[2*DW-1:DW];
            y_out <= acc[2*DW-1:DW];
        end
    end
endmodule