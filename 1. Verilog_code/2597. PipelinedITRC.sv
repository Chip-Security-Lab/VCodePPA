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
    
    always @(posedge clk) begin
        if (reset) begin
            stage1_irqs <= 0;
            stage2_irqs <= 0;
            stage1_valid <= 0;
            stage2_valid <= 0;
            stage1_vector <= 0;
            stage2_vector <= 0;
            irq_valid <= 0;
            irq_vector <= 0;
        end else begin
            // Stage 1: Capture and detect
            stage1_irqs <= irq_inputs;
            stage1_valid <= |irq_inputs;
            
            // Find highest priority using priority encoder
            if (irq_inputs[7]) stage1_vector <= 7;
            else if (irq_inputs[6]) stage1_vector <= 6;
            else if (irq_inputs[5]) stage1_vector <= 5;
            else if (irq_inputs[4]) stage1_vector <= 4;
            else if (irq_inputs[3]) stage1_vector <= 3;
            else if (irq_inputs[2]) stage1_vector <= 2;
            else if (irq_inputs[1]) stage1_vector <= 1;
            else if (irq_inputs[0]) stage1_vector <= 0;
            else stage1_vector <= 0;
            
            // Stage 2: Process and prepare
            stage2_irqs <= stage1_irqs;
            stage2_valid <= stage1_valid;
            stage2_vector <= stage1_vector;
            
            // Output stage
            irq_valid <= stage2_valid;
            irq_vector <= stage2_vector;
        end
    end
endmodule