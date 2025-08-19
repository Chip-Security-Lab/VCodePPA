//SystemVerilog
module piso_shifter_pipeline (
    input clk,
    input rst,
    input load,
    input [7:0] parallel_in,
    output serial_out,
    input flush,
    output valid_out
);
    // Stage 1: Load parallel data or shift register
    reg [7:0] shift_reg_stage1;
    reg load_stage1;
    reg [7:0] parallel_in_stage1;
    reg valid_stage1;

    // Stage 2: Prepare next state data
    reg [7:0] shift_reg_stage2;
    reg valid_stage2;

    // Stage 3: Output serialization
    reg serial_out_stage3;
    reg valid_stage3;

    // Stage 1: Capture inputs and load/shift decision (flattened control flow)
    always @(posedge clk) begin
        if (rst || flush) begin
            shift_reg_stage1     <= 8'b0;
            load_stage1          <= 1'b0;
            parallel_in_stage1   <= 8'b0;
            valid_stage1         <= 1'b0;
        end else if (load) begin
            shift_reg_stage1     <= parallel_in;
            parallel_in_stage1   <= parallel_in;
            load_stage1          <= 1'b1;
            valid_stage1         <= 1'b1 | valid_stage2;
        end else if (~load) begin
            shift_reg_stage1     <= shift_reg_stage2;
            parallel_in_stage1   <= 8'b0;
            load_stage1          <= 1'b0;
            valid_stage1         <= 1'b0 | valid_stage2;
        end
    end

    // Stage 2: Shift logic (flattened control flow)
    always @(posedge clk) begin
        if (rst || flush) begin
            shift_reg_stage2     <= 8'b0;
            valid_stage2         <= 1'b0;
        end else if (load_stage1) begin
            shift_reg_stage2     <= parallel_in_stage1;
            valid_stage2         <= valid_stage1;
        end else if (~load_stage1) begin
            shift_reg_stage2     <= {shift_reg_stage1[6:0], 1'b0};
            valid_stage2         <= valid_stage1;
        end
    end

    // Stage 3: Output serialization (flattened control flow)
    always @(posedge clk) begin
        if (rst || flush) begin
            serial_out_stage3    <= 1'b0;
            valid_stage3         <= 1'b0;
        end else begin
            serial_out_stage3    <= shift_reg_stage2[7];
            valid_stage3         <= valid_stage2;
        end
    end

    assign serial_out = serial_out_stage3;
    assign valid_out  = valid_stage3;

endmodule