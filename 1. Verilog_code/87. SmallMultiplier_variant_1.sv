//SystemVerilog
module SmallMultiplier(
    input  logic clk,
    input  logic rst_n,
    input  logic [1:0] a,
    input  logic [1:0] b,
    output logic [3:0] prod
);

    // Pipeline stage 1: Input register
    logic [1:0] a_reg;
    logic [1:0] b_reg;
    
    // Pipeline stage 2: Multiplication
    logic [3:0] mult_result;
    
    // Pipeline stage 3: Output register
    logic [3:0] prod_reg;

    // Stage 1: Input registration
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            a_reg <= '0;
            b_reg <= '0;
        end else begin
            a_reg <= a;
            b_reg <= b;
        end
    end

    // Stage 2: Multiplication
    always_comb begin
        mult_result = a_reg * b_reg;
    end

    // Stage 3: Output registration
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            prod_reg <= '0;
        end else begin
            prod_reg <= mult_result;
        end
    end

    // Output assignment
    assign prod = prod_reg;

endmodule