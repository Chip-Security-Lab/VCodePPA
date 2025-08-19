//SystemVerilog
module PriorityEncoder #(
    parameter WIDTH = 16
)(
    input [WIDTH-1:0] int_level,
    output reg [3:0] int_id
);
    always @(*) begin
        if (int_level[15]) int_id = 4'hF;
        else if (int_level[14]) int_id = 4'hE;
        else if (int_level[13]) int_id = 4'hD;
        else if (int_level[12]) int_id = 4'hC;
        else if (int_level[11]) int_id = 4'hB;
        else if (int_level[10]) int_id = 4'hA;
        else if (int_level[9]) int_id = 4'h9;
        else if (int_level[8]) int_id = 4'h8;
        else if (int_level[7]) int_id = 4'h7;
        else if (int_level[6]) int_id = 4'h6;
        else if (int_level[5]) int_id = 4'h5;
        else if (int_level[4]) int_id = 4'h4;
        else if (int_level[3]) int_id = 4'h3;
        else if (int_level[2]) int_id = 4'h2;
        else if (int_level[1]) int_id = 4'h1;
        else if (int_level[0]) int_id = 4'h0;
        else int_id = 4'h0;
    end
endmodule

module ResetSync #(
    parameter SYNC_STAGES = 2
)(
    input clk,
    input rst_async,
    output reg rst_sync
);
    reg [SYNC_STAGES-1:0] sync_ff;
    
    always @(posedge clk, posedge rst_async) begin
        if (rst_async) begin
            sync_ff <= {SYNC_STAGES{1'b1}};
            rst_sync <= 1'b1;
        end else begin
            sync_ff <= {sync_ff[SYNC_STAGES-2:0], 1'b0};
            rst_sync <= sync_ff[SYNC_STAGES-1];
        end
    end
endmodule

module ITRC_AsyncLevel #(
    parameter PRIORITY = 4'hF
)(
    input clk,
    input rst_async,
    input [15:0] int_level,
    input en,
    output reg [3:0] int_id
);
    reg [15:0] masked_int_reg;
    wire rst_sync;
    
    always @(posedge clk or posedge rst_async) begin
        if (rst_async) begin
            masked_int_reg <= 16'h0;
            int_id <= 4'h0;
        end else begin
            masked_int_reg <= int_level & {16{en}};
            int_id <= masked_int_reg[15] ? 4'hF :
                     masked_int_reg[14] ? 4'hE :
                     masked_int_reg[13] ? 4'hD :
                     masked_int_reg[12] ? 4'hC :
                     masked_int_reg[11] ? 4'hB :
                     masked_int_reg[10] ? 4'hA :
                     masked_int_reg[9] ? 4'h9 :
                     masked_int_reg[8] ? 4'h8 :
                     masked_int_reg[7] ? 4'h7 :
                     masked_int_reg[6] ? 4'h6 :
                     masked_int_reg[5] ? 4'h5 :
                     masked_int_reg[4] ? 4'h4 :
                     masked_int_reg[3] ? 4'h3 :
                     masked_int_reg[2] ? 4'h2 :
                     masked_int_reg[1] ? 4'h1 :
                     masked_int_reg[0] ? 4'h0 : 4'h0;
        end
    end
    
    ResetSync #(
        .SYNC_STAGES(2)
    ) u_reset_sync (
        .clk(clk),
        .rst_async(rst_async),
        .rst_sync(rst_sync)
    );
endmodule