//SystemVerilog
module grouped_ismu (
    input  wire        clk,        // Clock signal
    input  wire        rstn,       // Active-low reset
    input  wire [15:0] int_sources,// Interrupt sources
    input  wire [3:0]  group_mask, // Group mask signals
    output reg  [3:0]  group_int   // Output group interrupts
);
    // Optimized pipeline implementation
    
    // Pipeline stage 0: Input registers
    reg [15:0] int_sources_stage0;
    reg [3:0]  group_mask_stage0;
    reg        valid_stage0;
    
    // Pipeline stage 1: Combined group reduction
    reg [3:0]  group_or_stage1;
    reg [3:0]  group_mask_stage1;
    reg        valid_stage1;
    
    // Pipeline stage 2: Mask application
    reg [3:0]  masked_int_stage2;
    reg        valid_stage2;
    
    // Pipeline stage 0: Register inputs with enable logic
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            int_sources_stage0 <= 16'h0;
            group_mask_stage0  <= 4'h0;
            valid_stage0       <= 1'b0;
        end
        else begin
            int_sources_stage0 <= int_sources;
            group_mask_stage0  <= group_mask;
            valid_stage0       <= 1'b1; // Always valid after reset
        end
    end
    
    // Pipeline stage 1: Optimized group reduction
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            group_or_stage1   <= 4'h0;
            group_mask_stage1 <= 4'h0;
            valid_stage1      <= 1'b0;
        end
        else if (valid_stage0) begin
            // Combined OR reduction for better efficiency
            group_or_stage1[0] <= |int_sources_stage0[3:0];
            group_or_stage1[1] <= |int_sources_stage0[7:4];
            group_or_stage1[2] <= |int_sources_stage0[11:8];
            group_or_stage1[3] <= |int_sources_stage0[15:12];
            
            group_mask_stage1 <= group_mask_stage0;
            valid_stage1      <= valid_stage0;
        end
    end
    
    // Pipeline stage 2: Apply mask and generate pre-final
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            masked_int_stage2 <= 4'h0;
            valid_stage2      <= 1'b0;
        end
        else if (valid_stage1) begin
            // Vectorized operation for more efficient synthesis
            masked_int_stage2 <= group_or_stage1 & ~group_mask_stage1;
            valid_stage2      <= valid_stage1;
        end
    end
    
    // Pipeline stage 3: Output register
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            group_int <= 4'h0;
        end
        else if (valid_stage2) begin
            group_int <= masked_int_stage2;
        end
    end
    
endmodule