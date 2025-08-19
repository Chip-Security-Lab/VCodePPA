//SystemVerilog
// Buffer Control Module
module ICMU_BufferControl #(
    parameter DW = 32
)(
    input clk,
    input rst_sync,
    input buffer_swap,
    input context_valid,
    output reg buf_select,
    output wire write_enable
);
    assign write_enable = context_valid & ~buffer_swap;
    
    always @(posedge clk) begin
        if (rst_sync) begin
            buf_select <= 1'b0;
        end else if (buffer_swap) begin
            buf_select <= ~buf_select;
        end
    end
endmodule

// Buffer Storage Module
module ICMU_BufferStorage #(
    parameter DW = 32,
    parameter DEPTH = 8
)(
    input clk,
    input write_enable,
    input buf_select,
    input [DW-1:0] ctx_in,
    output reg [DW-1:0] buffer_out
);
    reg [DW-1:0] buffer_A [0:DEPTH-1];
    reg [DW-1:0] buffer_B [0:DEPTH-1];
    
    always @(*) begin
        if (buf_select) begin
            buffer_out = buffer_B[0];
        end else begin
            buffer_out = buffer_A[0];
        end
    end
    
    always @(posedge clk) begin
        if (write_enable) begin
            if (buf_select) begin
                buffer_B[0] <= ctx_in;
            end else begin
                buffer_A[0] <= ctx_in;
            end
        end
    end
endmodule

// Top Level Module
module ICMU_DoubleBuffer #(
    parameter DW = 32,
    parameter DEPTH = 8
)(
    input clk,
    input rst_sync,
    input buffer_swap,
    input context_valid,
    input [DW-1:0] ctx_in,
    output [DW-1:0] ctx_out
);
    wire buf_select;
    wire write_enable;
    wire [DW-1:0] buffer_out;
    
    ICMU_BufferControl #(
        .DW(DW)
    ) u_buffer_control (
        .clk(clk),
        .rst_sync(rst_sync),
        .buffer_swap(buffer_swap),
        .context_valid(context_valid),
        .buf_select(buf_select),
        .write_enable(write_enable)
    );
    
    ICMU_BufferStorage #(
        .DW(DW),
        .DEPTH(DEPTH)
    ) u_buffer_storage (
        .clk(clk),
        .write_enable(write_enable),
        .buf_select(buf_select),
        .ctx_in(ctx_in),
        .buffer_out(buffer_out)
    );
    
    assign ctx_out = buffer_out;
endmodule