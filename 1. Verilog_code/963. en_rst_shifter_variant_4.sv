//SystemVerilog
module en_rst_shifter (
    input wire clk,
    input wire rst,
    input wire en,
    input wire [1:0] mode,   // 00: hold, 01: shift left, 10: shift right
    input wire serial_in,
    output wire [3:0] data
);
    // Pipeline stage 1 registers - Input capture
    reg [1:0] mode_stage1;
    reg serial_in_stage1;
    reg [3:0] data_stage1;
    reg valid_stage1;
    
    // Pipeline stage 2 registers - Mode decode
    reg [1:0] mode_stage2;
    reg serial_in_stage2;
    reg [3:0] data_stage2;
    reg valid_stage2;
    
    // Pipeline stage 3 registers - Shift operation
    reg [3:0] shift_result_stage3;
    reg valid_stage3;
    
    // Pipeline stage 4 registers - Final output
    reg [3:0] data_stage4;
    
    // Combinational logic for stage 2 (mode decode)
    wire shift_left_stage2;
    wire shift_right_stage2;
    wire hold_stage2;
    
    assign shift_left_stage2 = (mode_stage2 == 2'b01);
    assign shift_right_stage2 = (mode_stage2 == 2'b10);
    assign hold_stage2 = (mode_stage2 == 2'b00);
    
    // Combinational logic for stage 3 (shift operation)
    wire [3:0] shift_left_result_stage3;
    wire [3:0] shift_right_result_stage3;
    
    assign shift_left_result_stage3 = {data_stage2[2:0], serial_in_stage2};
    assign shift_right_result_stage3 = {serial_in_stage2, data_stage2[3:1]};
    
    // Output assignment
    assign data = data_stage4;
    
    // Pipeline stage 1: Input capture
    always @(posedge clk) begin
        if (rst) begin
            mode_stage1 <= 2'b00;
            serial_in_stage1 <= 1'b0;
            data_stage1 <= 4'b0000;
            valid_stage1 <= 1'b0;
        end
        else if (en) begin
            mode_stage1 <= mode;
            serial_in_stage1 <= serial_in;
            data_stage1 <= (valid_stage1) ? data_stage4 : 4'b0000;
            valid_stage1 <= 1'b1;
        end
    end
    
    // Pipeline stage 2: Mode decode and preparation
    always @(posedge clk) begin
        if (rst) begin
            mode_stage2 <= 2'b00;
            serial_in_stage2 <= 1'b0;
            data_stage2 <= 4'b0000;
            valid_stage2 <= 1'b0;
        end
        else if (en) begin
            mode_stage2 <= mode_stage1;
            serial_in_stage2 <= serial_in_stage1;
            data_stage2 <= data_stage1;
            valid_stage2 <= valid_stage1;
        end
    end
    
    // Pipeline stage 3: Shift operation execution
    always @(posedge clk) begin
        if (rst) begin
            shift_result_stage3 <= 4'b0000;
            valid_stage3 <= 1'b0;
        end
        else if (en) begin
            if (valid_stage2) begin
                if (shift_left_stage2)
                    shift_result_stage3 <= shift_left_result_stage3;
                else if (shift_right_stage2)
                    shift_result_stage3 <= shift_right_result_stage3;
                else // hold
                    shift_result_stage3 <= data_stage2;
            end
            else
                shift_result_stage3 <= 4'b0000;
                
            valid_stage3 <= valid_stage2;
        end
    end
    
    // Pipeline stage 4: Final output
    always @(posedge clk) begin
        if (rst) begin
            data_stage4 <= 4'b0000;
        end
        else if (en) begin
            data_stage4 <= shift_result_stage3;
        end
    end
endmodule