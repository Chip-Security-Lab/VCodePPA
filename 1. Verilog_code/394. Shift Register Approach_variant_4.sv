//SystemVerilog
// Top-level module
module nand2_14 (
    input wire A, B,
    input wire clk,
    output wire Y
);
    // Internal connections between pipeline stages
    wire stage1_A, stage1_B;
    wire stage2_A, stage2_B;
    wire stage3_nand;
    
    // Stage 1: Input registration
    input_stage input_reg (
        .clk(clk),
        .A(A),
        .B(B),
        .A_reg(stage1_A),
        .B_reg(stage1_B)
    );
    
    // Stage 2: Middle registration
    middle_stage middle_reg (
        .clk(clk),
        .A_in(stage1_A),
        .B_in(stage1_B),
        .A_out(stage2_A),
        .B_out(stage2_B)
    );
    
    // Stage 3: Computation stage
    computation_stage compute (
        .clk(clk),
        .A(stage2_A),
        .B(stage2_B),
        .result(stage3_nand)
    );
    
    // Output stage
    output_stage output_reg (
        .clk(clk),
        .nand_result(stage3_nand),
        .Y(Y)
    );
endmodule

// Stage 1: Input registration module
module input_stage (
    input wire clk,
    input wire A, B,
    output reg A_reg, B_reg
);
    always @(posedge clk) begin
        A_reg <= A;
        B_reg <= B;
    end
endmodule

// Stage 2: Middle registration module
module middle_stage (
    input wire clk,
    input wire A_in, B_in,
    output reg A_out, B_out
);
    always @(posedge clk) begin
        A_out <= A_in;
        B_out <= B_in;
    end
endmodule

// Stage 3: Computation module
module computation_stage (
    input wire clk,
    input wire A, B,
    output reg result
);
    always @(posedge clk) begin
        result <= ~(A & B);
    end
endmodule

// Output stage module
module output_stage (
    input wire clk,
    input wire nand_result,
    output reg Y
);
    always @(posedge clk) begin
        Y <= nand_result;
    end
endmodule