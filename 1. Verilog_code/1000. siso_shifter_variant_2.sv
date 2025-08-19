//SystemVerilog
module siso_shifter(
    input wire clock, 
    input wire clear,
    input wire serial_data_in,
    output wire serial_data_out
);

    // Stage 1: Capture input and valid
    reg serial_data_in_stage1;
    reg valid_stage1;
    
    // Stage 2: Shift stage 1 output and valid
    reg [1:0] shift_reg_stage2;
    reg valid_stage2;
    
    // Stage 3: Shift stage 2 output and valid
    reg [2:0] shift_reg_stage3;
    reg valid_stage3;
    
    // Stage 4: Final output and valid
    reg [3:0] shift_reg_stage4;
    reg valid_stage4;
    
    // Flush logic for clear
    wire flush = clear;

    // Stage 1
    always @(posedge clock) begin
        if (flush) begin
            serial_data_in_stage1 <= 1'b0;
            valid_stage1 <= 1'b0;
        end else begin
            serial_data_in_stage1 <= serial_data_in;
            valid_stage1 <= 1'b1;
        end
    end

    // Stage 2
    always @(posedge clock) begin
        if (flush) begin
            shift_reg_stage2 <= 2'b00;
            valid_stage2 <= 1'b0;
        end else begin
            shift_reg_stage2 <= {shift_reg_stage2[0], serial_data_in_stage1};
            valid_stage2 <= valid_stage1;
        end
    end

    // Stage 3
    always @(posedge clock) begin
        if (flush) begin
            shift_reg_stage3 <= 3'b000;
            valid_stage3 <= 1'b0;
        end else begin
            shift_reg_stage3 <= {shift_reg_stage3[1:0], shift_reg_stage2[1]};
            valid_stage3 <= valid_stage2;
        end
    end

    // Stage 4
    always @(posedge clock) begin
        if (flush) begin
            shift_reg_stage4 <= 4'b0000;
            valid_stage4 <= 1'b0;
        end else begin
            shift_reg_stage4 <= {shift_reg_stage4[2:0], shift_reg_stage3[2]};
            valid_stage4 <= valid_stage3;
        end
    end

    assign serial_data_out = shift_reg_stage4[3];

endmodule