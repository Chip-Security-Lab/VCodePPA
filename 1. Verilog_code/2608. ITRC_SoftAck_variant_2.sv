//SystemVerilog
module ITRC_SoftAck #(
    parameter WIDTH = 8
)(
    input clk,
    input rst_n,
    input [WIDTH-1:0] int_src,
    input [WIDTH-1:0] ack_mask,
    output reg [WIDTH-1:0] pending
);

    reg [WIDTH-1:0] int_src_stage1;
    reg [WIDTH-1:0] ack_mask_stage1;
    reg [WIDTH-1:0] pending_stage1;
    reg [WIDTH-1:0] pending_stage2;

    // Stage 1: Register inputs and compute pending | int_src
    always @(posedge clk) begin
        if (!rst_n) begin
            int_src_stage1 <= {WIDTH{1'b0}};
            ack_mask_stage1 <= {WIDTH{1'b0}};
            pending_stage1 <= {WIDTH{1'b0}};
        end else begin
            int_src_stage1 <= int_src;
            ack_mask_stage1 <= ack_mask;
            pending_stage1 <= pending | int_src;
        end
    end

    // Stage 2: Compute final pending value
    always @(posedge clk) begin
        if (!rst_n) begin
            pending_stage2 <= {WIDTH{1'b0}};
        end else begin
            pending_stage2 <= pending_stage1 & ~ack_mask_stage1;
        end
    end

    // Output stage
    always @(posedge clk) begin
        if (!rst_n) begin
            pending <= {WIDTH{1'b0}};
        end else begin
            pending <= pending_stage2;
        end
    end

endmodule