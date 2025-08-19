//SystemVerilog
module rotate_left_shifter (
    input clk, rst, enable,
    output [7:0] data_out
);
    // Internal shift registers with increased pipeline stages
    reg [7:0] shift_reg_stage1;
    reg [7:0] shift_reg_stage2;
    reg [7:0] shift_reg_stage3;
    
    // Buffer registers for output with more pipeline stages
    reg [7:0] data_out_buf1;
    reg [7:0] data_out_buf2;
    reg [7:0] data_out_buf3;
    reg [7:0] data_out_buf4;
    
    // Intermediate rotation registers to break down complex rotation operation
    reg [7:0] rotate_temp1;
    reg [7:0] rotate_temp2;
    
    // Assign output through final buffer
    assign data_out = data_out_buf4;
    
    // Pre-load with pattern
    initial begin
        shift_reg_stage1 = 8'b10101010;
        shift_reg_stage2 = 8'b10101010;
        shift_reg_stage3 = 8'b10101010;
        rotate_temp1 = 8'b10101010;
        rotate_temp2 = 8'b10101010;
        data_out_buf1 = 8'b10101010;
        data_out_buf2 = 8'b10101010;
        data_out_buf3 = 8'b10101010;
        data_out_buf4 = 8'b10101010;
    end
    
    // Stage 1: Start rotation calculation - prepare the rotated bit
    always @(posedge clk) begin
        if (rst)
            rotate_temp1 <= 8'b10101010;
        else if (enable)
            rotate_temp1 <= {shift_reg_stage3[6:0], shift_reg_stage3[7]};
    end
    
    // Stage 2: Continue rotation operation
    always @(posedge clk) begin
        if (rst)
            rotate_temp2 <= 8'b10101010;
        else if (enable)
            rotate_temp2 <= rotate_temp1;
    end
    
    // Stage 3: Complete the rotation
    always @(posedge clk) begin
        if (rst)
            shift_reg_stage1 <= 8'b10101010;
        else if (enable)
            shift_reg_stage1 <= rotate_temp2;
    end
    
    // Shift register pipeline stages
    always @(posedge clk) begin
        if (rst) begin
            shift_reg_stage2 <= 8'b10101010;
            shift_reg_stage3 <= 8'b10101010;
        end
        else if (enable) begin
            shift_reg_stage2 <= shift_reg_stage1;
            shift_reg_stage3 <= shift_reg_stage2;
        end
    end
    
    // Output buffer pipeline stages
    always @(posedge clk) begin
        data_out_buf1 <= shift_reg_stage1;
        data_out_buf2 <= data_out_buf1;
        data_out_buf3 <= data_out_buf2;
        data_out_buf4 <= data_out_buf3;
    end
endmodule