//SystemVerilog
//------------------------------------------------------------------------------
// Top-level NOR2 Pipeline Logic Module (Hierarchical, Pipelined Structure)
//------------------------------------------------------------------------------
module nor2_logic (
    input  wire clk,
    input  wire rst_n,
    input  wire in_a,
    input  wire in_b,
    output wire out_y
);

    // Stage 1: Input Registering
    reg stage1_a;
    reg stage1_b;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage1_a <= 1'b0;
            stage1_b <= 1'b0;
        end else begin
            stage1_a <= in_a;
            stage1_b <= in_b;
        end
    end

    // Stage 2: OR Logic with Registered Output
    wire stage2_or_result;
    or2_pipeline_stage u_or2_stage (
        .clk(clk),
        .rst_n(rst_n),
        .in_a(stage1_a),
        .in_b(stage1_b),
        .or_out(stage2_or_result)
    );

    // Stage 3: NOT Logic with Registered Output (Final Output)
    not_pipeline_stage u_not_stage (
        .clk(clk),
        .rst_n(rst_n),
        .in_data(stage2_or_result),
        .out_data(out_y)
    );

endmodule

//------------------------------------------------------------------------------
// or2_pipeline_stage: Registered 2-input OR gate (Pipeline Stage)
//------------------------------------------------------------------------------
module or2_pipeline_stage (
    input  wire clk,
    input  wire rst_n,
    input  wire in_a,
    input  wire in_b,
    output reg  or_out
);
    wire or_comb;
    assign or_comb = in_a | in_b;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            or_out <= 1'b0;
        else
            or_out <= or_comb;
    end
endmodule

//------------------------------------------------------------------------------
// not_pipeline_stage: Registered inverter (Pipeline Stage)
//------------------------------------------------------------------------------
module not_pipeline_stage (
    input  wire clk,
    input  wire rst_n,
    input  wire in_data,
    output reg  out_data
);
    wire not_comb;
    assign not_comb = ~in_data;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            out_data <= 1'b0;
        else
            out_data <= not_comb;
    end
endmodule