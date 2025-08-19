//SystemVerilog
module siso_shift_reg #(parameter WIDTH = 8) (
    input  wire clk, rst, data_in,
    output wire data_out
);
    // Pipeline stage registers
    reg [WIDTH-1:0] shift_reg_stage1;
    reg [WIDTH-1:0] shift_reg_stage2;
    reg [WIDTH-1:0] shift_reg_stage3;
    
    // Pipeline control signals
    reg valid_stage1, valid_stage2, valid_stage3;
    
    // Pipeline input data registers
    reg data_in_stage1;
    
    // LUT components - maintained from original design
    reg [WIDTH-1:0] lut_outputs [0:1];
    wire lut_select;
    
    // Initialize lookup table values
    initial begin
        lut_outputs[0] = {WIDTH{1'b0}};  // Reset value
        lut_outputs[1] = {{(WIDTH-1){1'b0}}, 1'b1};  // Value for single bit shift-in
    end
    
    // LUT select signal - determines which LUT output to use
    assign lut_select = !rst && data_in_stage1;
    
    // Stage 1: Input registration and shift calculation preparation
    always @(posedge clk) begin
        if (rst) begin
            data_in_stage1 <= 1'b0;
            valid_stage1 <= 1'b0;
        end else begin
            data_in_stage1 <= data_in;
            valid_stage1 <= 1'b1;
        end
    end
    
    // Stage 2: Perform shift operation
    always @(posedge clk) begin
        if (rst) begin
            shift_reg_stage1 <= {WIDTH{1'b0}};
            valid_stage2 <= 1'b0;
        end else if (valid_stage1) begin
            shift_reg_stage1 <= (shift_reg_stage3 << 1) | lut_outputs[lut_select][0];
            valid_stage2 <= valid_stage1;
        end
    end
    
    // Stage 3: Additional processing (could include error checking or other operations)
    always @(posedge clk) begin
        if (rst) begin
            shift_reg_stage2 <= {WIDTH{1'b0}};
            valid_stage3 <= 1'b0;
        end else if (valid_stage2) begin
            shift_reg_stage2 <= shift_reg_stage1;
            valid_stage3 <= valid_stage2;
        end
    end
    
    // Final stage: Output preparation
    always @(posedge clk) begin
        if (rst) begin
            shift_reg_stage3 <= {WIDTH{1'b0}};
        end else if (valid_stage3) begin
            shift_reg_stage3 <= shift_reg_stage2;
        end
    end
    
    // Output is the MSB of the final stage register
    assign data_out = shift_reg_stage3[WIDTH-1];
    
endmodule