//SystemVerilog
module sipo_register(
    input wire clk,
    input wire rst,
    input wire enable,
    input wire serial_in,
    output reg [7:0] parallel_out
);

    // Stage 1: Shift input and stage 1 valid
    reg [6:0] shift_reg_stage1;
    reg serial_in_stage1;
    reg valid_stage1;

    // Stage 2: Form full shift_reg and stage 2 valid
    reg [7:0] shift_reg_stage2;
    reg valid_stage2;

    // Stage 3: Output register and valid
    reg [7:0] parallel_out_stage3;
    reg valid_stage3;

    // Pipeline flush logic
    wire flush;
    assign flush = rst;

    // Stage 1: Capture input and shift lower bits
    always @(posedge clk) begin
        if (flush) begin
            shift_reg_stage1 <= 7'b0;
            serial_in_stage1 <= 1'b0;
            valid_stage1 <= 1'b0;
        end else if (enable) begin
            shift_reg_stage1 <= shift_reg_stage2[6:0];
            serial_in_stage1 <= serial_in;
            valid_stage1 <= 1'b1;
        end else begin
            valid_stage1 <= 1'b0;
        end
    end

    // Stage 2: Complete shift register
    always @(posedge clk) begin
        if (flush) begin
            shift_reg_stage2 <= 8'b0;
            valid_stage2 <= 1'b0;
        end else if (valid_stage1) begin
            shift_reg_stage2 <= {shift_reg_stage1, serial_in_stage1};
            valid_stage2 <= 1'b1;
        end else begin
            valid_stage2 <= 1'b0;
        end
    end

    // Stage 3: Output register
    always @(posedge clk) begin
        if (flush) begin
            parallel_out_stage3 <= 8'b0;
            valid_stage3 <= 1'b0;
        end else if (valid_stage2) begin
            parallel_out_stage3 <= shift_reg_stage2;
            valid_stage3 <= 1'b1;
        end else begin
            valid_stage3 <= 1'b0;
        end
    end

    // Output assignment
    always @(posedge clk) begin
        if (flush) begin
            parallel_out <= 8'b0;
        end else if (valid_stage3) begin
            parallel_out <= parallel_out_stage3;
        end
    end

endmodule