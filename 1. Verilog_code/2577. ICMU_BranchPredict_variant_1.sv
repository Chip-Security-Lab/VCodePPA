//SystemVerilog
// Branch Prediction Buffer Module
module BP_Buffer #(
    parameter DW = 64,
    parameter PRED_SIZE = 8
)(
    input clk,
    input [2:0] wr_addr,
    input [DW-1:0] wr_data,
    input [2:0] rd_addr,
    output reg [DW-1:0] rd_data
);
    reg [DW-1:0] buffer [0:PRED_SIZE-1];
    
    always @(posedge clk) begin
        buffer[wr_addr] <= wr_data;
        rd_data <= buffer[rd_addr];
    end
endmodule

// Branch Prediction Control Module
module BP_Control #(
    parameter PRED_SIZE = 8
)(
    input clk,
    input branch_taken,
    output reg [2:0] pred_index,
    output reg [2:0] next_index
);
    always @(posedge clk) begin
        if (branch_taken) begin
            pred_index <= 0;
        end else begin
            if (pred_index < PRED_SIZE-1) begin
                next_index <= pred_index + 1;
            end else begin
                next_index <= 0;
            end
            pred_index <= next_index;
        end
    end
endmodule

// Top Level Branch Prediction Module
module ICMU_BranchPredict #(
    parameter DW = 64,
    parameter PRED_SIZE = 8
)(
    input clk,
    input branch_taken,
    input [DW-1:0] current_ctx,
    output reg [DW-1:0] pred_ctx
);
    wire [2:0] pred_index;
    wire [2:0] next_index;
    wire [DW-1:0] buffer_out;
    
    BP_Buffer #(
        .DW(DW),
        .PRED_SIZE(PRED_SIZE)
    ) buffer_inst (
        .clk(clk),
        .wr_addr(pred_index),
        .wr_data(current_ctx),
        .rd_addr(pred_index),
        .rd_data(buffer_out)
    );
    
    BP_Control #(
        .PRED_SIZE(PRED_SIZE)
    ) control_inst (
        .clk(clk),
        .branch_taken(branch_taken),
        .pred_index(pred_index),
        .next_index(next_index)
    );
    
    always @(posedge clk) begin
        pred_ctx <= buffer_out;
    end
endmodule