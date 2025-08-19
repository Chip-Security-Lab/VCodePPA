//SystemVerilog
// Top level module - Pipelined AND gate with enable control with forward retiming
module and_gate_enable (
    input  wire clk,     // Clock signal
    input  wire rst_n,   // Active-low reset
    input  wire a,       // Input A
    input  wire b,       // Input B
    input  wire enable,  // Enable signal
    output wire y        // Output Y
);
    // Forward retimed architecture
    wire and_result;                // Combinational AND result
    reg  stage1_and_result;         // Stage 1 registered AND result
    reg  stage1_enable;             // Stage 1 registered enable
    wire stage2_output;             // Stage 2 output
    reg  stage2_output_reg;         // Final registered output

    // Perform AND operation directly on inputs without registering first
    assign and_result = a & b;

    // Stage 1: Register the AND result and enable signal
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage1_and_result <= 1'b0;
            stage1_enable <= 1'b0;
        end else begin
            stage1_and_result <= and_result;
            stage1_enable <= enable;
        end
    end

    // Enable control with balanced logic path
    assign stage2_output = stage1_enable ? stage1_and_result : 1'b0;

    // Final output stage
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage2_output_reg <= 1'b0;
        end else begin
            stage2_output_reg <= stage2_output;
        end
    end

    // Output assignment
    assign y = stage2_output_reg;

endmodule