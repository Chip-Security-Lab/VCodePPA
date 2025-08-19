//SystemVerilog
module gen_decoder #(
    parameter WIDTH = 3
)(
    input logic clk,
    input logic rst_n,
    input logic [WIDTH-1:0] addr,
    input logic enable,
    output logic [2**WIDTH-1:0] dec_out
);

    // Pipeline stage 1: Address comparison
    logic [2**WIDTH-1:0] addr_match;
    logic [2**WIDTH-1:0] addr_match_reg;
    
    // Pipeline stage 2: Enable gating
    logic [2**WIDTH-1:0] enabled_output;
    logic [2**WIDTH-1:0] enabled_output_reg;

    // Address comparison logic
    genvar i;
    generate
        for (i = 0; i < 2**WIDTH; i = i + 1) begin: addr_compare
            assign addr_match[i] = (addr == i);
        end
    endgenerate

    // Pipeline stage 1: Register address comparison results
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            addr_match_reg <= '0;
        end else begin
            addr_match_reg <= addr_match;
        end
    end

    // Enable gating logic
    assign enabled_output = enable ? addr_match_reg : '0;

    // Pipeline stage 2: Register final output
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            enabled_output_reg <= '0;
        end else begin
            enabled_output_reg <= enabled_output;
        end
    end

    // Output assignment
    assign dec_out = enabled_output_reg;

endmodule