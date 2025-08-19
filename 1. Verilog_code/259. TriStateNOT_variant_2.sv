//SystemVerilog
module TriStateNOT(
    input        clk,      // Clock input
    input        rst_n,    // Active low reset
    input        oe,       // Output enable
    input  [3:0] in,       // Input data bus
    output [3:0] out       // Output data bus
);
    // Optimized pipeline structure with fewer stages
    reg        oe_r1, oe_r2;
    reg  [3:0] in_r1;
    reg  [3:0] out_r;      // Output register
    
    // Combined pipeline stages for better timing and resource utilization
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            oe_r1   <= 1'b0;
            oe_r2   <= 1'b0;
            in_r1   <= 4'b0000;
            out_r   <= 4'b0000;
        end else begin
            // First stage
            oe_r1   <= oe;
            in_r1   <= in;
            
            // Second stage - combine inversion and enable logic
            oe_r2   <= oe_r1;
            out_r   <= oe_r1 ? ~in_r1 : 4'b0000;
        end
    end
    
    // Optimized tri-state output logic with direct enable control
    // Reduces potential glitches by using the same enable signal for data and tri-state control
    assign out = oe_r2 ? out_r : 4'bzzzz;

endmodule