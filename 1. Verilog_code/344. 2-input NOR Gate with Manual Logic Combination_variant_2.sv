//SystemVerilog
module nor2_logic (
    input  wire clk,
    input  wire rst_n,
    input  wire A,
    input  wire B,
    output wire Y
);

    wire or_result_comb;
    reg  or_result_reg;
    wire nor_result_comb;
    reg  nor_result_reg;

    // Combinational logic: OR operation
    assign or_result_comb = A | B;

    // Sequential logic: Register the OR result
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            or_result_reg <= 1'b0;
        else
            or_result_reg <= or_result_comb;
    end

    // Combinational logic: NOR (invert the OR result)
    assign nor_result_comb = ~or_result_reg;

    // Sequential logic: Register the NOR result
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            nor_result_reg <= 1'b0;
        else
            nor_result_reg <= nor_result_comb;
    end

    // Output assignment
    assign Y = nor_result_reg;

endmodule