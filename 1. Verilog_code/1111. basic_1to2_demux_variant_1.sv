//SystemVerilog
// Top-level 1-to-2 Demultiplexer Module with Structured Pipelined Data Path

module pipelined_1to2_demux (
    input  wire clk,           // Clock input for pipelining
    input  wire rst_n,         // Active-low synchronous reset
    input  wire data_in,       // Input data to be routed
    input  wire sel,           // Selection line
    output wire out0,          // Output line 0
    output wire out1           // Output line 1
);

    // Stage 1: Input Registering
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

    // Stage 2: Combinational Demux Logic
    wire out0_stage2;
    wire out1_stage2;

    assign out0_stage2 = (sel_stage1 == 1'b0) ? data_in_stage1 : 1'b0;
    assign out1_stage2 = (sel_stage1 == 1'b1) ? data_in_stage1 : 1'b0;

    // Stage 3: Output Registering
    reg out0_reg;
    reg out1_reg;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            out0_reg <= 1'b0;
            out1_reg <= 1'b0;
        end else begin
            out0_reg <= out0_stage2;
            out1_reg <= out1_stage2;
        end
    end

    assign out0 = out0_reg;
    assign out1 = out1_reg;

endmodule