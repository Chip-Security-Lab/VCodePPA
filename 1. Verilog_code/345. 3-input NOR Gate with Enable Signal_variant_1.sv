//SystemVerilog
// Top-level module: Pipelined Hierarchical NOR3 with Enable Control
module nor3_enable (
    input  wire clk,
    input  wire rst_n,
    input  wire A,
    input  wire B,
    input  wire C,
    input  wire enable,
    output wire Y
);

    // Stage 1: Input Registration
    reg A_stage1, B_stage1, C_stage1, enable_stage1;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            A_stage1      <= 1'b0;
            B_stage1      <= 1'b0;
            C_stage1      <= 1'b0;
            enable_stage1 <= 1'b0;
        end else begin
            A_stage1      <= A;
            B_stage1      <= B;
            C_stage1      <= C;
            enable_stage1 <= enable;
        end
    end

    // Stage 2: NOR3 Logic
    wire nor3_stage2;
    nor3_logic_pipeline u_nor3_logic_pipeline (
        .clk(clk),
        .rst_n(rst_n),
        .in_a(A_stage1),
        .in_b(B_stage1),
        .in_c(C_stage1),
        .nor_out(nor3_stage2)
    );

    // Stage 2: Enable Registration (align enable with NOR3 output)
    reg enable_stage2;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            enable_stage2 <= 1'b0;
        else
            enable_stage2 <= enable_stage1;
    end

    // Stage 3: Enable Control Logic
    wire y_stage3;
    enable_control_pipeline u_enable_control_pipeline (
        .clk(clk),
        .rst_n(rst_n),
        .enable(enable_stage2),
        .logic_in(nor3_stage2),
        .y_out(y_stage3)
    );

    // Output Register (for balanced pipeline, optional)
    reg Y_reg;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            Y_reg <= 1'b0;
        else
            Y_reg <= y_stage3;
    end

    assign Y = Y_reg;

endmodule

// -----------------------------------------------------------------------------
// Submodule: Registered 3-input NOR Logic (Pipeline Stage)
// -----------------------------------------------------------------------------
module nor3_logic_pipeline (
    input  wire clk,
    input  wire rst_n,
    input  wire in_a,
    input  wire in_b,
    input  wire in_c,
    output reg  nor_out
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            nor_out <= 1'b0;
        else
            nor_out <= ~in_a & ~in_b & ~in_c;
    end
endmodule

// -----------------------------------------------------------------------------
// Submodule: Registered Enable Control Logic (Pipeline Stage)
// -----------------------------------------------------------------------------
module enable_control_pipeline (
    input  wire clk,
    input  wire rst_n,
    input  wire enable,
    input  wire logic_in,
    output reg  y_out
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            y_out <= 1'b0;
        else
            y_out <= ~enable | logic_in;
    end
endmodule