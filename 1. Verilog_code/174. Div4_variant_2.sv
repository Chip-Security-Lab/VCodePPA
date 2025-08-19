//SystemVerilog
module Div4(
    input clk,
    input rst_n,
    input [7:0] dividend,
    input [7:0] divisor,
    output reg [7:0] quotient,
    output reg [7:0] remainder
);

    // Pipeline stages
    reg [8:0] partial_remainder [0:7];
    reg [7:0] partial_quotient [0:7];
    reg [7:0] divisor_reg;
    
    // Pipeline control
    reg [2:0] stage;
    reg valid_out;
    
    // Main pipeline process
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage <= 3'd0;
            valid_out <= 1'b0;
            quotient <= 8'd0;
            remainder <= 8'd0;
            divisor_reg <= 8'd0;
        end else begin
            // Stage 0: Input registration
            partial_remainder[0] <= {1'b0, dividend};
            partial_quotient[0] <= 8'd0;
            divisor_reg <= divisor;
            
            // Pipeline stages 1-7
            for (integer i = 1; i < 8; i = i + 1) begin
                partial_remainder[i] <= partial_remainder[i-1];
                partial_quotient[i] <= partial_quotient[i-1];
                
                if (partial_remainder[i-1][8:4] >= divisor_reg) begin
                    partial_remainder[i] <= partial_remainder[i-1] - {divisor_reg, 1'b0};
                    partial_quotient[i][7-(i-1)] <= 1'b1;
                end
            end
            
            // Final stage: Output registration
            quotient <= partial_quotient[7];
            remainder <= partial_remainder[7][7:0] >> 1;
            valid_out <= 1'b1;
        end
    end

endmodule