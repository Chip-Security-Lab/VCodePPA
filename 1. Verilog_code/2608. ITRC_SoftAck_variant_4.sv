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

    // Pipeline stage 1 registers
    reg [WIDTH-1:0] int_src_stage1;
    reg [WIDTH-1:0] ack_mask_stage1;
    reg [WIDTH-1:0] pending_stage1;
    reg valid_stage1;
    
    // Pipeline stage 2 registers
    reg [WIDTH-1:0] pending_stage2;
    reg valid_stage2;
    
    // Pipeline stage 1 logic
    always @(posedge clk) begin
        if (!rst_n) begin
            int_src_stage1 <= 0;
            ack_mask_stage1 <= 0;
            pending_stage1 <= 0;
            valid_stage1 <= 0;
        end else begin
            int_src_stage1 <= int_src;
            ack_mask_stage1 <= ack_mask;
            pending_stage1 <= pending;
            valid_stage1 <= 1'b1;
        end
    end
    
    // Pipeline stage 2 logic
    always @(posedge clk) begin
        if (!rst_n) begin
            pending_stage2 <= 0;
            valid_stage2 <= 0;
        end else if (valid_stage1) begin
            pending_stage2 <= (pending_stage1 | int_src_stage1) & ~ack_mask_stage1;
            valid_stage2 <= 1'b1;
        end else begin
            valid_stage2 <= 0;
        end
    end
    
    // Output assignment
    always @(posedge clk) begin
        if (!rst_n) begin
            pending <= 0;
        end else if (valid_stage2) begin
            pending <= pending_stage2;
        end
    end

endmodule