//SystemVerilog - IEEE 1364-2005
// Top-level module for 3-input AND gate with pipelined structure
module and_gate_3_delay (
    input  wire      clk,      // Clock input
    input  wire      rst_n,    // Active-low reset
    input  wire      a,        // Input A
    input  wire      b,        // Input B
    input  wire      c,        // Input C
    output wire      y         // Output Y
);
    // Pipeline stage signals
    wire stage1_result;
    reg  stage1_result_reg;
    reg  c_delayed;
    wire stage2_result;
    
    // Stage 1: First AND operation with A and B inputs
    and_stage_one first_stage (
        .in1(a),
        .in2(b),
        .out(stage1_result)
    );
    
    // Pipeline registers to improve timing
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage1_result_reg <= 1'b0;
            c_delayed <= 1'b0;
        end else begin
            stage1_result_reg <= stage1_result;
            c_delayed <= c;
        end
    end
    
    // Stage 2: Final AND operation with proper pipelining
    final_and_stage final_stage (
        .in1(stage1_result_reg),
        .in2(c_delayed),
        .out(stage2_result)
    );
    
    // Output delay modeling through a simple delay module
    delay_model output_delay (
        .clk(clk),
        .rst_n(rst_n),
        .in(stage2_result),
        .out(y)
    );
    
endmodule

// First stage performs AND operation between two inputs
module and_stage_one (
    input  wire in1,
    input  wire in2,
    output wire out
);
    // Direct combinational logic for first stage
    assign out = in1 & in2;
endmodule

// Final stage for the AND operation
module final_and_stage (
    input  wire in1,
    input  wire in2,
    output wire out
);
    // Combinational logic for final stage
    assign out = in1 & in2;
endmodule

// Delay model implementation using synchronous logic
module delay_model (
    input  wire clk,
    input  wire rst_n,
    input  wire in,
    output reg  out
);
    // Intermediate registers for delay modeling
    reg delay_stage;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            delay_stage <= 1'b0;
            out <= 1'b0;
        end else begin
            delay_stage <= in;
            out <= delay_stage;
        end
    end
endmodule