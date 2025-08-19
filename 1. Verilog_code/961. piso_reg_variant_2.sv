//SystemVerilog
module piso_reg (
    input clk, clear_b, load,
    input [7:0] parallel_in,
    output serial_out
);
    // Pipeline stage registers with improved initial values
    reg [3:0] stage1_data;
    reg [3:0] stage2_data;
    reg stage1_valid;
    reg stage2_valid;
    
    // Output bit selection
    wire active_bit = stage1_valid ? stage1_data[3] : stage2_data[3];
    
    // Combined output enable logic
    wire output_active = stage1_valid || stage2_valid;
    
    // Stage 1 (handles upper 4 bits)
    always @(posedge clk or negedge clear_b) begin
        if (!clear_b) begin
            stage1_data <= 4'h0;
            stage1_valid <= 1'b0;
        end else if (load) begin
            stage1_data <= parallel_in[7:4];
            stage1_valid <= 1'b1;
        end else if (stage1_valid) begin
            if (!stage2_valid) begin
                // Transition from stage1 to stage2 when stage2 is ready
                stage1_valid <= 1'b0;
            end else begin
                // Shift operation with better bit selection
                stage1_data <= {stage1_data[2:0], 1'b0};
            end
        end
    end
    
    // Stage 2 (handles lower 4 bits)
    always @(posedge clk or negedge clear_b) begin
        if (!clear_b) begin
            stage2_data <= 4'h0;
            stage2_valid <= 1'b0;
        end else if (load) begin
            stage2_data <= parallel_in[3:0];
            stage2_valid <= 1'b1;
        end else if (stage1_valid && !stage2_valid) begin
            // Load from stage1 when stage1 is done and stage2 is ready
            stage2_data <= stage1_data;
            stage2_valid <= 1'b1;
        end else if (stage2_valid) begin
            // Optimized comparison and shift logic
            if (stage2_data[3:1] == 3'h0 && !stage2_data[0] && !stage1_valid) begin
                // When stage2 is done processing (all bits shifted out)
                stage2_valid <= 1'b0;
            end else begin
                // Shift operation for stage2
                stage2_data <= {stage2_data[2:0], 1'b0};
            end
        end
    end
    
    // Optimized output assignment with single conditional
    assign serial_out = output_active ? active_bit : 1'b0;
    
endmodule