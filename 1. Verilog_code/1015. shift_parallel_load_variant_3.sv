//SystemVerilog
// Top-level module: shift_parallel_load_pipeline
// Function: Optimized pipelined parallel load shift register with valid/flush control (reduced pipeline stages)

module shift_parallel_load_pipeline #(
    parameter DEPTH = 4
)(
    input  wire        clk,
    input  wire        rst_n,
    input  wire        load,
    input  wire [7:0]  pdata,
    input  wire        valid_in,
    input  wire        flush,
    output wire [7:0]  sout,
    output wire        valid_out
);

    // Stage 1: Combined input register and parallel load/shift control
    reg  [7:0] shift_reg_stage1;
    reg        valid_stage1;
    reg        flush_stage1;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            shift_reg_stage1 <= 8'b0;
            valid_stage1     <= 1'b0;
            flush_stage1     <= 1'b0;
        end else begin
            if (flush) begin
                shift_reg_stage1 <= 8'b0;
                valid_stage1     <= 1'b0;
                flush_stage1     <= 1'b1;
            end else if (valid_in) begin
                shift_reg_stage1 <= load ? pdata : {shift_reg_stage1[6:0], 1'b0};
                valid_stage1     <= 1'b1;
                flush_stage1     <= 1'b0;
            end else begin
                shift_reg_stage1 <= shift_reg_stage1;
                valid_stage1     <= 1'b0;
                flush_stage1     <= flush;
            end
        end
    end

    // Stage 2: Output register
    reg [7:0] sout_stage2;
    reg       valid_stage2;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sout_stage2  <= 8'b0;
            valid_stage2 <= 1'b0;
        end else begin
            if (flush_stage1) begin
                sout_stage2  <= 8'b0;
                valid_stage2 <= 1'b0;
            end else if (valid_stage1) begin
                sout_stage2  <= shift_reg_stage1;
                valid_stage2 <= 1'b1;
            end else begin
                sout_stage2  <= sout_stage2;
                valid_stage2 <= 1'b0;
            end
        end
    end

    assign sout      = sout_stage2;
    assign valid_out = valid_stage2;

endmodule