//SystemVerilog
module SignedDiv(
    input wire clk,
    input wire rst_n,
    input signed [7:0] num,
    input signed [7:0] den,
    output reg signed [7:0] q
);

    // Pipeline registers
    reg signed [7:0] num_reg;
    reg signed [7:0] den_reg;
    reg den_zero_reg;
    
    // Division result register
    reg signed [7:0] div_result;
    
    // Pipeline stage 1: Input registration with optimized zero detection
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            num_reg <= 8'd0;
            den_reg <= 8'd0;
            den_zero_reg <= 1'b0;
        end else begin
            num_reg <= num;
            den_reg <= den;
            den_zero_reg <= ~|den;  // Optimized zero detection using reduction OR
        end
    end
    
    // Pipeline stage 2: Division operation with early termination
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            div_result <= 8'd0;
        end else begin
            div_result <= den_zero_reg ? 8'd0 : num_reg / den_reg;
        end
    end
    
    // Pipeline stage 3: Output selection and registration
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            q <= 8'h80;
        end else begin
            q <= den_zero_reg ? 8'h80 : div_result;
        end
    end

endmodule