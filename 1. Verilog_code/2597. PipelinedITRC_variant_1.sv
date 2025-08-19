//SystemVerilog
module PipelinedITRC #(parameter WIDTH=8) (
    input wire clk, reset,
    input wire [WIDTH-1:0] irq_inputs,
    output reg irq_valid,
    output reg [2:0] irq_vector
);
    reg [WIDTH-1:0] stage1_irqs, stage2_irqs;
    reg stage1_valid, stage2_valid;
    reg [2:0] stage1_vector, stage2_vector;
    reg [2:0] priority_encoder;
    
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
            priority_encoder <= 0;
        end else begin
            // Stage 1: Capture and detect
            stage1_irqs <= irq_inputs;
            stage1_valid <= |irq_inputs;
            
            // Priority encoder using standard case with explicit conditions
            case(1'b1)
                irq_inputs[7]: priority_encoder <= 7;
                irq_inputs[6]: priority_encoder <= 6;
                irq_inputs[5]: priority_encoder <= 5;
                irq_inputs[4]: priority_encoder <= 4;
                irq_inputs[3]: priority_encoder <= 3;
                irq_inputs[2]: priority_encoder <= 2;
                irq_inputs[1]: priority_encoder <= 1;
                irq_inputs[0]: priority_encoder <= 0;
                default: priority_encoder <= 0;
            endcase
            
            stage1_vector <= priority_encoder;
            
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