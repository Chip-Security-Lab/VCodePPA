//SystemVerilog
module piso_shifter(
    input clk,
    input rst,
    input load,
    input [7:0] parallel_in,
    output serial_out
);

    // Pipeline Stage 1: Input Control and Latch
    reg [7:0] parallel_in_stage1;
    reg load_stage1;
    reg rst_stage1;

    always @(posedge clk) begin
        parallel_in_stage1 <= parallel_in;
        load_stage1 <= load;
        rst_stage1 <= rst;
    end

    // Pipeline Stage 2: Shift Register Data Calculation
    reg [7:0] shift_reg_stage2;
    reg load_stage2;
    reg rst_stage2;

    always @(posedge clk) begin
        load_stage2 <= load_stage1;
        rst_stage2 <= rst_stage1;
        if (rst_stage1)
            shift_reg_stage2 <= 8'b0;
        else if (load_stage1)
            shift_reg_stage2 <= parallel_in_stage1;
        else
            shift_reg_stage2 <= {shift_reg_stage2[6:0], 1'b0};
    end

    // Pipeline Stage 3: Output Register
    reg serial_out_stage3;

    always @(posedge clk) begin
        serial_out_stage3 <= shift_reg_stage2[7];
    end

    assign serial_out = serial_out_stage3;

endmodule