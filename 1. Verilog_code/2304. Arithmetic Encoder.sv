module arithmetic_encoder #(
    parameter PRECISION = 16
)(
    input                     clk,
    input                     rst,
    input                     symbol_valid,
    input              [7:0]  symbol,
    output reg                code_valid,
    output reg [PRECISION-1:0] lower_bound,
    output reg [PRECISION-1:0] upper_bound
);
    // Simplified probability model (fixed)
    reg [PRECISION-1:0] prob_table [0:3];
    reg [PRECISION-1:0] range;
    
    initial begin
        prob_table[0] = 0;                   // Start
        prob_table[1] = PRECISION/4;         // 25%
        prob_table[2] = PRECISION/2;         // 50%
        prob_table[3] = (3*PRECISION)/4;     // 75%
    end
    
    always @(posedge clk) begin
        if (rst) begin
            lower_bound <= 0;
            upper_bound <= {PRECISION{1'b1}}; // All 1's
            code_valid <= 0;
        end else if (symbol_valid) begin
            range <= upper_bound - lower_bound + 1;
            
            // Use 2 MSBs of symbol to select probability range (simplified)
            upper_bound <= lower_bound + (range * prob_table[symbol[7:6]+1])/PRECISION - 1;
            lower_bound <= lower_bound + (range * prob_table[symbol[7:6]])/PRECISION;
            
            code_valid <= 1;
        end else begin
            code_valid <= 0;
        end
    end
endmodule