//SystemVerilog
module ICMU_DoubleBuffer #(
    parameter DW = 32,
    parameter DEPTH = 8
)(
    input clk,
    input rst_sync,
    input buffer_swap,
    input context_valid,
    input [DW-1:0] ctx_in,
    output [DW-1:0] ctx_out,
    output valid_out
);
    // Buffer memories
    reg [DW-1:0] buffer_A [0:DEPTH-1];
    reg [DW-1:0] buffer_B [0:DEPTH-1];
    
    // Pipeline registers
    reg buf_select_stage1;
    reg buf_select_stage2;
    reg [DW-1:0] ctx_in_stage1;
    reg context_valid_stage1;
    reg buffer_swap_stage1;
    reg [DW-1:0] ctx_out_stage2;
    reg valid_out_stage2;
    
    // Stage 1: Input registration and buffer selection
    always @(posedge clk) begin
        if (rst_sync) begin
            buf_select_stage1 <= 1'b0;
            ctx_in_stage1 <= {DW{1'b0}};
            context_valid_stage1 <= 1'b0;
            buffer_swap_stage1 <= 1'b0;
        end else begin
            buf_select_stage1 <= buffer_swap ? ~buf_select_stage1 : buf_select_stage1;
            ctx_in_stage1 <= ctx_in;
            context_valid_stage1 <= context_valid;
            buffer_swap_stage1 <= buffer_swap;
        end
    end
    
    // Stage 2: Buffer write and output selection
    always @(posedge clk) begin
        if (rst_sync) begin
            buf_select_stage2 <= 1'b0;
            ctx_out_stage2 <= {DW{1'b0}};
            valid_out_stage2 <= 1'b0;
        end else begin
            buf_select_stage2 <= buf_select_stage1;
            
            // Write to appropriate buffer
            if (context_valid_stage1) begin
                if (buf_select_stage1)
                    buffer_B[0] <= ctx_in_stage1;
                else
                    buffer_A[0] <= ctx_in_stage1;
            end
            
            // Select output
            ctx_out_stage2 <= buf_select_stage1 ? buffer_B[0] : buffer_A[0];
            valid_out_stage2 <= context_valid_stage1;
        end
    end
    
    // Output assignments
    assign ctx_out = ctx_out_stage2;
    assign valid_out = valid_out_stage2;
endmodule