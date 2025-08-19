//SystemVerilog
// Top-level module for 1-to-2 Demultiplexer with pipeline and structured dataflow

module basic_1to2_demux (
    input  wire clk,             // Clock input for pipelining
    input  wire rst_n,           // Active-low synchronous reset
    input  wire data_in,         // Input data to be routed
    input  wire sel,             // Selection line
    output wire out0,            // Output line 0
    output wire out1             // Output line 1
);

    // Stage 1: Input latching
    reg data_in_stage1;
    reg sel_stage1;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_in_stage1 <= 1'b0;
            sel_stage1     <= 1'b0;
        end else begin
            data_in_stage1 <= data_in;
            sel_stage1     <= sel;
        end
    end

    // Stage 2: Demux logic
    reg demux_out0_stage2;
    reg demux_out1_stage2;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            demux_out0_stage2 <= 1'b0;
            demux_out1_stage2 <= 1'b0;
        end else begin
            demux_out0_stage2 <= (sel_stage1 == 1'b0) ? data_in_stage1 : 1'b0;
            demux_out1_stage2 <= (sel_stage1 == 1'b1) ? data_in_stage1 : 1'b0;
        end
    end

    // Stage 3: Output register (optional for deeper pipelining and improved timing)
    reg out0_stage3;
    reg out1_stage3;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            out0_stage3 <= 1'b0;
            out1_stage3 <= 1'b0;
        end else begin
            out0_stage3 <= demux_out0_stage2;
            out1_stage3 <= demux_out1_stage2;
        end
    end

    assign out0 = out0_stage3;
    assign out1 = out1_stage3;

endmodule