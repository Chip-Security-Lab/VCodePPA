//SystemVerilog
module nor2_logic (
    input  wire clk,
    input  wire rst_n,
    input  wire A,
    input  wire B,
    output wire Y
);
    // Internal wires for combinational logic
    wire or_comb_result;
    wire nor_comb_result;

    // Registers for pipelined stages
    reg  or_stage_reg;
    reg  nor_stage_reg;

    // Combinational logic: OR operation
    assign or_comb_result = A | B;

    // Sequential logic: Register OR result
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            or_stage_reg <= 1'b0;
        else
            or_stage_reg <= or_comb_result;
    end

    // Combinational logic: NOR operation
    assign nor_comb_result = ~or_stage_reg;

    // Sequential logic: Register NOR result
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            nor_stage_reg <= 1'b0;
        else
            nor_stage_reg <= nor_comb_result;
    end

    // Output assignment
    assign Y = nor_stage_reg;

endmodule