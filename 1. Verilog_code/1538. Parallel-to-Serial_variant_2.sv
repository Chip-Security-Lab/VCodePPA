//SystemVerilog
module p2s_shadow_reg #(
    parameter WIDTH = 8
)(
    input wire clk,
    input wire rst_n,
    input wire [WIDTH-1:0] parallel_in,
    input wire load_parallel,
    input wire shift_en,
    output wire serial_out,
    output wire [WIDTH-1:0] shadow_data
);
    // Pipeline stage 1 registers
    reg [WIDTH-1:0] shift_reg_stage1;
    reg [WIDTH-1:0] shadow_data_stage1;
    reg valid_stage1;
    
    // Pipeline stage 2 registers
    reg [WIDTH-1:0] shift_reg_stage2;
    reg [WIDTH-1:0] shadow_data_stage2;
    reg valid_stage2;
    
    // Pipeline stage 3 registers
    reg [WIDTH-1:0] shift_reg_stage3;
    reg [WIDTH-1:0] shadow_data_stage3;
    
    // Stage 1: Input capture and initial processing
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            shift_reg_stage1 <= 0;
            shadow_data_stage1 <= 0;
            valid_stage1 <= 0;
        end
        else begin
            valid_stage1 <= load_parallel || shift_en;
            
            if (load_parallel)
                shift_reg_stage1 <= parallel_in;
            else if (shift_en)
                shift_reg_stage1 <= {shift_reg_stage3[WIDTH-2:0], 1'b0};
                
            if (load_parallel)
                shadow_data_stage1 <= parallel_in;
            else
                shadow_data_stage1 <= shadow_data_stage3;
        end
    end
    
    // Stage 2: Intermediate processing
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            shift_reg_stage2 <= 0;
            shadow_data_stage2 <= 0;
            valid_stage2 <= 0;
        end
        else begin
            valid_stage2 <= valid_stage1;
            shift_reg_stage2 <= shift_reg_stage1;
            shadow_data_stage2 <= shadow_data_stage1;
        end
    end
    
    // Stage 3: Final processing and output generation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            shift_reg_stage3 <= 0;
            shadow_data_stage3 <= 0;
        end
        else if (valid_stage2) begin
            shift_reg_stage3 <= shift_reg_stage2;
            shadow_data_stage3 <= shadow_data_stage2;
        end
    end
    
    // Serial output is MSB of the final stage
    assign serial_out = shift_reg_stage3[WIDTH-1];
    
    // Shadow data output
    assign shadow_data = shadow_data_stage3;
    
endmodule