//SystemVerilog
// Top-level module: Structured 2-input NOR gate with pipelined data path (flattened if-else)
module nor2_conditional (
    input  wire clk,
    input  wire rst_n,
    input  wire A,
    input  wire B,
    output wire Y
);

    // Stage 1: Register inputs for clear data flow
    reg stage1_A;
    reg stage1_B;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage1_A <= 1'b0;
            stage1_B <= 1'b0;
        end else if (rst_n && clk) begin // Flattened: explicit condition for clarity
            stage1_A <= A;
            stage1_B <= B;
        end
    end

    // Stage 2: OR operation with registered result
    wire or_stage_result;
    or2_pipeline u_or2_pipeline (
        .clk(clk),
        .rst_n(rst_n),
        .in1(stage1_A),
        .in2(stage1_B),
        .or_out(or_stage_result)
    );

    // Stage 3: Registered NOR logic
    nor_pipeline_core u_nor_pipeline_core (
        .clk(clk),
        .rst_n(rst_n),
        .or_in(or_stage_result),
        .nor_out(Y)
    );

endmodule

// Submodule: Pipelined 2-input OR gate with output register (flattened if-else)
module or2_pipeline (
    input  wire clk,
    input  wire rst_n,
    input  wire in1,
    input  wire in2,
    output wire or_out
);
    reg or_out_reg;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            or_out_reg <= 1'b0;
        else if (rst_n && clk)
            or_out_reg <= in1 | in2;
    end
    assign or_out = or_out_reg;
endmodule

// Submodule: Registered NOR logic (inverter with pipeline register) (flattened if-else)
module nor_pipeline_core (
    input  wire clk,
    input  wire rst_n,
    input  wire or_in,
    output wire nor_out
);
    reg nor_out_reg;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            nor_out_reg <= 1'b0;
        else if (rst_n && clk)
            nor_out_reg <= ~or_in;
    end
    assign nor_out = nor_out_reg;
endmodule