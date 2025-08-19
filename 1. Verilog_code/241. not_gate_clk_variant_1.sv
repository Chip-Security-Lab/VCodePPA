//SystemVerilog
// Submodule: Inverter
// Function: Performs a logical NOT operation
module inverter (
    input wire data_in,
    output wire data_out
);
    assign data_out = ~data_in;
endmodule

// Top module: not_gate_clk_hierarchical_pipelined
// Function: Clocked NOT gate with hierarchical structure and pipelining
module not_gate_clk_hierarchical_pipelined (
    input wire clk,
    input wire rst_n,
    input wire valid_in,
    input wire A,
    output wire valid_out,
    output wire Y
);

    // Stage 1: Input register and Inverter
    reg valid_stage1;
    reg A_stage1;
    wire inverted_A_stage1;

    inverter u_inverter_stage1 (
        .data_in(A_stage1),
        .data_out(inverted_A_stage1)
    );

    always @ (posedge clk) begin
        if (~rst_n) begin
            valid_stage1 <= 1'b0;
            A_stage1 <= 1'b0;
        end else begin
            valid_stage1 <= valid_in;
            A_stage1 <= A;
        end
    end

    // Stage 2: Output register
    reg valid_stage2;
    reg Y_stage2;

    always @ (posedge clk) begin
        if (~rst_n) begin
            valid_stage2 <= 1'b0;
            Y_stage2 <= 1'b0;
        end else begin
            valid_stage2 <= valid_stage1;
            Y_stage2 <= inverted_A_stage1;
        end
    end

    assign valid_out = valid_stage2;
    assign Y = Y_stage2;

endmodule