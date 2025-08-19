//SystemVerilog
module IVMU_FixedPriority #(parameter WIDTH=8, ADDR=4) (
    input clk, rst_n,
    input [WIDTH-1:0] int_req,
    output reg [ADDR-1:0] vec_addr,
    output wire [WIDTH-1:0] debug_sub_result
);

// Refactored logic for vec_addr using nested if-else
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        vec_addr <= 0;
    end else begin
        // Priority encoding based on highest set bit
        if (int_req[7]) begin
            vec_addr <= 4'h7;
        end else if (int_req[6]) begin
            vec_addr <= 4'h6;
        end else if (int_req[5]) begin
            vec_addr <= 4'h5;
        end else begin
            // Default case: no recognized high priority request
            vec_addr <= 0;
        end
    end
end

// Logic for subtraction using two's complement addition
// Example: Calculate int_req - 8'd10
// A - B = A + (-B)
// -B in two's complement = (~B) + 1

wire [WIDTH-1:0] sub_operand_b = 10;          // The number to subtract (B)
wire [WIDTH-1:0] inverted_b = ~sub_operand_b; // Bitwise NOT of B (~B)
wire [WIDTH-1:0] neg_b = inverted_b + 1;      // Two's complement of B (-B)

// Perform addition: int_req + neg_b (A + (-B))
wire [WIDTH-1:0] sub_result_calc = int_req + neg_b;

// Assign the result to the new output
assign debug_sub_result = sub_result_calc;

endmodule