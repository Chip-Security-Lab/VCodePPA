//SystemVerilog
module PipelinedITRC #(parameter WIDTH=8) (
    input wire clk, reset,
    input wire [WIDTH-1:0] irq_inputs,
    output reg irq_valid,
    output reg [2:0] irq_vector
);
    // Pipeline stages
    reg [WIDTH-1:0] stage1_irqs, stage2_irqs;
    reg stage1_valid, stage2_valid;
    reg [2:0] stage1_vector, stage2_vector;

    // Stage 1: Capture and detect
    always @(posedge clk) begin
        if (reset) begin
            stage1_irqs <= 0;
            stage1_valid <= 0;
            stage1_vector <= 0;
        end else begin
            stage1_irqs <= irq_inputs;
            stage1_valid <= |irq_inputs;

            // Find highest priority using priority encoder
            case (irq_inputs)
                8'b10000000: stage1_vector <= 7;
                8'b01000000: stage1_vector <= 6;
                8'b00100000: stage1_vector <= 5;
                8'b00010000: stage1_vector <= 4;
                8'b00001000: stage1_vector <= 3;
                8'b00000100: stage1_vector <= 2;
                8'b00000010: stage1_vector <= 1;
                8'b00000001: stage1_vector <= 0;
                default: stage1_vector <= 0;
            endcase
        end
    end

    // Stage 2: Process and prepare
    always @(posedge clk) begin
        if (reset) begin
            stage2_irqs <= 0;
            stage2_valid <= 0;
            stage2_vector <= 0;
            irq_valid <= 0;
            irq_vector <= 0;
        end else begin
            stage2_irqs <= stage1_irqs;
            stage2_valid <= stage1_valid;
            stage2_vector <= stage1_vector;

            // Output stage
            irq_valid <= stage2_valid;
            irq_vector <= stage2_vector;
        end
    end
endmodule