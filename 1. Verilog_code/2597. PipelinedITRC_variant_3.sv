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
    
    // Optimized priority encoder using binary search
    wire [2:0] priority_vector;
    wire [3:0] upper_half = irq_inputs[7:4];
    wire [3:0] lower_half = irq_inputs[3:0];
    
    assign priority_vector = |upper_half ? 
                           (upper_half[3] ? 3'd7 :
                            upper_half[2] ? 3'd6 :
                            upper_half[1] ? 3'd5 : 3'd4) :
                           (lower_half[3] ? 3'd3 :
                            lower_half[2] ? 3'd2 :
                            lower_half[1] ? 3'd1 : 3'd0);
    
    // Optimized valid signal using parallel OR
    wire irq_valid_next;
    assign irq_valid_next = |irq_inputs;
    
    always @(posedge clk) begin
        if (reset) begin
            {stage1_irqs, stage2_irqs} <= 0;
            {stage1_valid, stage2_valid} <= 0;
            {stage1_vector, stage2_vector} <= 0;
            {irq_valid, irq_vector} <= 0;
        end else begin
            // Stage 1: Capture and detect
            stage1_irqs <= irq_inputs;
            stage1_valid <= irq_valid_next;
            stage1_vector <= priority_vector;
            
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