//SystemVerilog - IEEE 1364-2005
module DynamicWidthShifter #(parameter MAX_WIDTH=16) (
    input clk,
    input rst,  // Added reset signal for pipeline control
    input [4:0] current_width,
    input serial_in,
    input valid_in,  // Pipeline control signal
    output reg valid_out,  // Pipeline status signal
    output reg serial_out
);
    // Pipeline stage 1 registers
    reg [MAX_WIDTH-2:0] shift_buffer_stage1;
    reg input_reg_stage1;
    reg [4:0] current_width_stage1;
    reg valid_stage1;
    
    // Pipeline stage 2 registers
    reg [MAX_WIDTH-2:0] shift_buffer_stage2;
    reg input_reg_stage2;
    reg [4:0] current_width_stage2;
    reg valid_stage2;
    
    // Stage 1: Input capture and shift operation
    always @(posedge clk) begin
        if (rst) begin
            shift_buffer_stage1 <= 0;
            input_reg_stage1 <= 0;
            current_width_stage1 <= 0;
            valid_stage1 <= 0;
        end
        else begin
            input_reg_stage1 <= serial_in;
            shift_buffer_stage1 <= {shift_buffer_stage2[MAX_WIDTH-3:0], input_reg_stage2};
            current_width_stage1 <= current_width;
            valid_stage1 <= valid_in;
        end
    end
    
    // Stage 2: Intermediate processing
    always @(posedge clk) begin
        if (rst) begin
            shift_buffer_stage2 <= 0;
            input_reg_stage2 <= 0;
            current_width_stage2 <= 0;
            valid_stage2 <= 0;
        end
        else begin
            shift_buffer_stage2 <= shift_buffer_stage1;
            input_reg_stage2 <= input_reg_stage1;
            current_width_stage2 <= current_width_stage1;
            valid_stage2 <= valid_stage1;
        end
    end
    
    // Stage 3: Output determination based on width
    always @(posedge clk) begin
        if (rst) begin
            serial_out <= 0;
            valid_out <= 0;
        end
        else begin
            valid_out <= valid_stage2;
            if (current_width_stage2 == 1)
                serial_out <= input_reg_stage2;
            else
                serial_out <= shift_buffer_stage2[current_width_stage2-2];
        end
    end
endmodule