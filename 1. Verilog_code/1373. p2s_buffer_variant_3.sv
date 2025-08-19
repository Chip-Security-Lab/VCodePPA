//SystemVerilog
//IEEE 1364-2005
module p2s_buffer (
    input wire clk,
    input wire load,
    input wire shift,
    input wire [7:0] parallel_in,
    output reg serial_out
);
    // Stage 1 - Input and processing registers
    reg [7:0] shift_reg_stage1;
    reg load_stage1, shift_stage1;
    reg [7:0] parallel_in_stage1;
    
    // Stage 2 - Intermediate processing registers
    reg [7:0] shift_reg_stage2;
    reg load_stage2, shift_stage2;
    
    // Stage 3 - Final processing and output registers
    reg [7:0] shift_reg_stage3;
    
    // Stage 1: Input Capture
    always @(posedge clk) begin
        parallel_in_stage1 <= parallel_in;
        load_stage1 <= load;
        shift_stage1 <= shift;
    end
    
    // Stage 2: Data Processing
    always @(posedge clk) begin
        load_stage2 <= load_stage1;
        shift_stage2 <= shift_stage1;
        
        if (load_stage1)
            shift_reg_stage2 <= parallel_in_stage1;
        else if (shift_stage1)
            shift_reg_stage2 <= {shift_reg_stage1[6:0], 1'b0};
        else
            shift_reg_stage2 <= shift_reg_stage1;
    end
    
    // Stage 3: Output Generation
    always @(posedge clk) begin
        shift_reg_stage3 <= shift_reg_stage2;
        shift_reg_stage1 <= shift_reg_stage3;
        
        if (load_stage2)
            serial_out <= parallel_in_stage1[7];
        else if (shift_stage2)
            serial_out <= shift_reg_stage2[6];
    end
endmodule