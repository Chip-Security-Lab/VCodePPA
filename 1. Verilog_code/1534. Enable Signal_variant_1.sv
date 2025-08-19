//SystemVerilog
//IEEE 1364-2005 Verilog
module enabled_shadow_reg #(
    parameter DATA_WIDTH = 12
)(
    input wire clock,
    input wire reset_n,
    input wire enable,
    input wire [DATA_WIDTH-1:0] data_input,
    input wire shadow_capture,
    output reg [DATA_WIDTH-1:0] shadow_output
);
    // Pipeline stage 1 - Input registration
    reg enable_stage1;
    reg shadow_capture_stage1;
    reg [DATA_WIDTH-1:0] data_input_stage1;
    
    // Pipeline stage 2 - Main data registration
    reg enable_stage2;
    reg shadow_capture_stage2;
    reg [DATA_WIDTH-1:0] data_reg_stage2;
    
    // Pipeline stage 3 - Shadow output stage
    reg valid_stage3;
    
    // Pipeline control signals
    reg valid_stage1, valid_stage2;
    
    // Stage 1: Input registration pipeline
    always @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            enable_stage1 <= 1'b0;
            shadow_capture_stage1 <= 1'b0;
            data_input_stage1 <= {DATA_WIDTH{1'b0}};
            valid_stage1 <= 1'b0;
        end else begin
            enable_stage1 <= enable;
            shadow_capture_stage1 <= shadow_capture;
            data_input_stage1 <= data_input;
            valid_stage1 <= 1'b1; // Data is valid after first cycle
        end
    end
    
    // Stage 2: Main data processing pipeline
    always @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            data_reg_stage2 <= {DATA_WIDTH{1'b0}};
            enable_stage2 <= 1'b0;
            shadow_capture_stage2 <= 1'b0;
            valid_stage2 <= 1'b0;
        end else if (valid_stage1) begin
            enable_stage2 <= enable_stage1;
            shadow_capture_stage2 <= shadow_capture_stage1;
            valid_stage2 <= valid_stage1;
            
            if (enable_stage1)
                data_reg_stage2 <= data_input_stage1;
        end
    end
    
    // Stage 3: Shadow output pipeline
    always @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            shadow_output <= {DATA_WIDTH{1'b0}};
            valid_stage3 <= 1'b0;
        end else if (valid_stage2) begin
            valid_stage3 <= valid_stage2;
            
            if (shadow_capture_stage2 && enable_stage2)
                shadow_output <= data_reg_stage2;
        end
    end
endmodule