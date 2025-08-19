//SystemVerilog
module IIR_LPF #(parameter W=8, ALPHA=4) (
    input clk, rst_n,
    input [W-1:0] din,
    output reg [W-1:0] dout
);

    // Pipeline stage 1: Input and coefficient multiplication
    reg [W-1:0] din_reg;
    reg [W-1:0] dout_reg;
    reg [W-1:0] alpha_coeff;
    reg [W-1:0] beta_coeff;
    
    // Pipeline stage 2: Multiplication results
    reg [15:0] alpha_mult;
    reg [15:0] beta_mult;
    
    // Pipeline stage 3: Summation and shift
    reg [15:0] sum_result;
    
    // Initialize coefficients
    initial begin
        alpha_coeff = ALPHA;
        beta_coeff = 8'd255 - ALPHA;
    end
    
    // Pipeline stage 1: Register inputs and coefficients
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            din_reg <= 0;
            dout_reg <= 0;
        end else begin
            din_reg <= din;
            dout_reg <= dout;
        end
    end
    
    // Pipeline stage 2: Perform multiplications
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            alpha_mult <= 0;
            beta_mult <= 0;
        end else begin
            alpha_mult <= alpha_coeff * din_reg;
            beta_mult <= beta_coeff * dout_reg;
        end
    end
    
    // Pipeline stage 3: Sum and shift
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sum_result <= 0;
            dout <= 0;
        end else begin
            sum_result <= alpha_mult + beta_mult;
            dout <= sum_result >> 8;
        end
    end
    
endmodule