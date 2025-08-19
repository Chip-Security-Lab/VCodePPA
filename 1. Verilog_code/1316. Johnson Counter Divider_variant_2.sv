//SystemVerilog
module johnson_divider #(parameter WIDTH = 4) (
    input wire clock_i, rst_i,
    output wire clock_o
);
    // Johnson counter registers for each pipeline stage
    reg [WIDTH-1:0] johnson_stage1;
    reg [WIDTH-1:0] johnson_stage2;
    reg [WIDTH-1:0] johnson_stage3;
    
    // Valid signals to track active data through pipeline
    reg valid_stage1, valid_stage2, valid_stage3;
    
    // Enable signals for better control and power efficiency
    wire enable_stage1, enable_stage2, enable_stage3;
    
    // First pipeline stage - input processing
    always @(posedge clock_i) begin
        if (rst_i) begin
            johnson_stage1 <= {WIDTH{1'b0}};
            valid_stage1 <= 1'b0;
        end else if (enable_stage1) begin
            johnson_stage1 <= {~johnson_stage3[0], johnson_stage3[WIDTH-1:1]};
            valid_stage1 <= 1'b1;
        end
    end
    
    // Second pipeline stage - intermediate processing
    always @(posedge clock_i) begin
        if (rst_i) begin
            johnson_stage2 <= {WIDTH{1'b0}};
            valid_stage2 <= 1'b0;
        end else if (enable_stage2) begin
            johnson_stage2 <= johnson_stage1;
            valid_stage2 <= valid_stage1;
        end
    end
    
    // Third pipeline stage - output processing
    always @(posedge clock_i) begin
        if (rst_i) begin
            johnson_stage3 <= {WIDTH{1'b0}};
            valid_stage3 <= 1'b0;
        end else if (enable_stage3) begin
            johnson_stage3 <= johnson_stage2;
            valid_stage3 <= valid_stage2;
        end
    end
    
    // Enable logic - implementing stall/ready functionality
    // In this design, all stages are always enabled after reset
    // This can be extended with external ready signals if needed
    assign enable_stage1 = 1'b1;
    assign enable_stage2 = valid_stage1;
    assign enable_stage3 = valid_stage2;
    
    // Output assignment with validity check
    assign clock_o = valid_stage3 ? johnson_stage3[0] : 1'b0;
    
    // Clock gating cells could be added here for power optimization
    // This would require technology-specific cells
endmodule