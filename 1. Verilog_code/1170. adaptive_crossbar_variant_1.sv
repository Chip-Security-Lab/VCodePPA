//SystemVerilog
module adaptive_crossbar (
    input wire clk, rst,
    input wire [31:0] data_in,
    input wire [1:0] mode,
    input wire [7:0] sel,
    input wire update_config,
    output reg [31:0] data_out
);
    // ---------------------------------------------------------
    // Stage 1: Input Registration and Segmentation
    // ---------------------------------------------------------
    // Input registers to improve timing
    reg [31:0] data_in_reg;
    reg [1:0] mode_reg;
    reg [7:0] sel_reg;
    reg update_config_reg;
    
    // Data segmentation pipeline registers
    reg [7:0] data_seg_reg [0:3];
    
    // Input registration stage
    always @(posedge clk) begin
        if (rst) begin
            data_in_reg <= 32'h00000000;
            mode_reg <= 2'b00;
            sel_reg <= 8'h00;
            update_config_reg <= 1'b0;
            
            // Clear data segments - parallel assignment for better synthesis
            {data_seg_reg[3], data_seg_reg[2], data_seg_reg[1], data_seg_reg[0]} <= 32'h0;
        end else begin
            data_in_reg <= data_in;
            mode_reg <= mode;
            sel_reg <= sel;
            update_config_reg <= update_config;
            
            // Segment data in the pipeline - using slicing for better readability
            {data_seg_reg[3], data_seg_reg[2], data_seg_reg[1], data_seg_reg[0]} <= data_in;
        end
    end
    
    // ---------------------------------------------------------
    // Configuration Memory and Management
    // ---------------------------------------------------------
    // Configuration registers for different modes - combined declaration
    reg [1:0] config_sel[0:3][0:3]; // [mode][output]
    reg [1:0] active_mode_reg; // Pipeline register for mode propagation
    
    // Configuration update logic with optimized structure
    always @(posedge clk) begin
        if (rst) begin
            // Initialize configurations using range assignments
            for (int m = 0; m < 4; m++) begin
                for (int o = 0; o < 4; o++) begin
                    config_sel[m][o] <= o; // Identity mapping
                end
            end
            
            active_mode_reg <= 2'b00;
        end else begin
            // Propagate mode through pipeline
            active_mode_reg <= mode_reg;
            
            // Update configuration for current mode - vectorized approach
            if (update_config_reg) begin
                config_sel[mode_reg][0] <= sel_reg[1:0];
                config_sel[mode_reg][1] <= sel_reg[3:2];
                config_sel[mode_reg][2] <= sel_reg[5:4];
                config_sel[mode_reg][3] <= sel_reg[7:6];
            end
        end
    end
    
    // ---------------------------------------------------------
    // Stage 2: Crossbar Switching Logic - Optimized mux structure
    // ---------------------------------------------------------
    // Intermediate pipeline registers for crossbar outputs
    reg [7:0] crossbar_out_reg [0:3];
    
    // Optimized crossbar selection logic
    always @(posedge clk) begin
        if (rst) begin
            {crossbar_out_reg[3], crossbar_out_reg[2], crossbar_out_reg[1], crossbar_out_reg[0]} <= 32'h0;
        end else begin
            // Route data through crossbar using parametric indexing
            for (int i = 0; i < 4; i++) begin
                // Two-stage comparison approach for optimized routing logic
                case (config_sel[active_mode_reg][i])
                    2'b00: crossbar_out_reg[i] <= data_seg_reg[0];
                    2'b01: crossbar_out_reg[i] <= data_seg_reg[1];
                    2'b10: crossbar_out_reg[i] <= data_seg_reg[2];
                    2'b11: crossbar_out_reg[i] <= data_seg_reg[3];
                endcase
            end
        end
    end
    
    // ---------------------------------------------------------
    // Stage 3: Output Formation
    // ---------------------------------------------------------
    // Final output registration stage - vectorized implementation
    always @(posedge clk) begin
        if (rst) begin
            data_out <= 32'h00000000;
        end else begin
            // Assemble output using concatenation for better synthesis
            data_out <= {crossbar_out_reg[3], crossbar_out_reg[2], 
                         crossbar_out_reg[1], crossbar_out_reg[0]};
        end
    end
endmodule