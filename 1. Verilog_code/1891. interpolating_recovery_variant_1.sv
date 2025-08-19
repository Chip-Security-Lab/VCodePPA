//SystemVerilog
module interpolating_recovery #(
    parameter WIDTH = 12
)(
    input wire clk,
    input wire valid_in,
    input wire [WIDTH-1:0] sample_a,
    input wire [WIDTH-1:0] sample_b,
    output reg [WIDTH-1:0] interpolated,
    output reg valid_out
);
    // Intermediate registers to store input values
    reg [WIDTH-1:0] sample_a_reg, sample_b_reg;
    reg valid_in_reg;
    reg [WIDTH-1:0] sum_reg;
    
    // First stage: register inputs
    always @(posedge clk) begin
        sample_a_reg <= sample_a;
        sample_b_reg <= sample_b;
        valid_in_reg <= valid_in;
    end
    
    // Second stage: perform addition
    always @(posedge clk) begin
        sum_reg <= sample_a_reg + sample_b_reg;
    end
    
    // Final stage: perform shifting and control logic
    always @(posedge clk) begin
        interpolated <= valid_in_reg ? sum_reg >> 1 : interpolated;
        valid_out <= valid_in_reg;
    end
endmodule