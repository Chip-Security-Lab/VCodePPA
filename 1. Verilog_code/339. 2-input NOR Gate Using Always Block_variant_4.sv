//SystemVerilog
// Top-level pipeline NOR2 module with hierarchical submodules
module nor2_pipeline (
    input  wire clk,
    input  wire rst_n,
    input  wire in_a,
    input  wire in_b,
    output wire out_y
);

    // Internal signals for inter-stage connections
    wire stage1_a_out;
    wire stage1_b_out;
    wire stage2_nor_out;
    wire stage3_out;

    // Stage 1: Input register module
    nor2_input_register u_input_register (
        .clk        (clk),
        .rst_n      (rst_n),
        .in_a       (in_a),
        .in_b       (in_b),
        .reg_a_out  (stage1_a_out),
        .reg_b_out  (stage1_b_out)
    );

    // Stage 2: Combinational NOR logic register module
    nor2_logic_register u_logic_register (
        .clk        (clk),
        .rst_n      (rst_n),
        .in_a       (stage1_a_out),
        .in_b       (stage1_b_out),
        .nor_out    (stage2_nor_out)
    );

    // Stage 3: Output register module
    nor2_output_register u_output_register (
        .clk        (clk),
        .rst_n      (rst_n),
        .in_y       (stage2_nor_out),
        .out_y      (stage3_out)
    );

    assign out_y = stage3_out;

endmodule

// ---------------------------------------------------------------------------
// Submodule: nor2_input_register
// Description: Registers input signals in_a and in_b on rising edge of clk
// ---------------------------------------------------------------------------
module nor2_input_register (
    input  wire clk,
    input  wire rst_n,
    input  wire in_a,
    input  wire in_b,
    output reg  reg_a_out,
    output reg  reg_b_out
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            reg_a_out <= 1'b0;
            reg_b_out <= 1'b0;
        end else begin
            reg_a_out <= in_a;
            reg_b_out <= in_b;
        end
    end
endmodule

// ---------------------------------------------------------------------------
// Submodule: nor2_logic_register
// Description: Computes NOR of two registered inputs and registers the result
// ---------------------------------------------------------------------------
module nor2_logic_register (
    input  wire clk,
    input  wire rst_n,
    input  wire in_a,
    input  wire in_b,
    output reg  nor_out
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            nor_out <= 1'b0;
        end else begin
            nor_out <= (~in_a) & (~in_b);
        end
    end
endmodule

// ---------------------------------------------------------------------------
// Submodule: nor2_output_register
// Description: Registers the final NOR output result
// ---------------------------------------------------------------------------
module nor2_output_register (
    input  wire clk,
    input  wire rst_n,
    input  wire in_y,
    output reg  out_y
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            out_y <= 1'b0;
        end else begin
            out_y <= in_y;
        end
    end
endmodule