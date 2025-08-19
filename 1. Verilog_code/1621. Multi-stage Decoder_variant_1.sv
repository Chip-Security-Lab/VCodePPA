//SystemVerilog
module two_stage_decoder (
    input clk,
    input rst_n,
    input req,
    output reg ack,
    input [3:0] address,
    output reg [15:0] select
);
    reg [3:0] stage1_out;
    reg [15:0] select_reg;
    reg ack_reg;
    
    // First stage decodes top 2 bits using Dadda multiplier approach
    always @(*) begin
        if (address[3:2] == 2'b00)
            stage1_out = 4'b0001;
        else if (address[3:2] == 2'b01)
            stage1_out = 4'b0010;
        else if (address[3:2] == 2'b10)
            stage1_out = 4'b0100;
        else if (address[3:2] == 2'b11)
            stage1_out = 4'b1000;
        else
            stage1_out = 4'b0000;
    end
    
    // Second stage uses bottom 2 bits with optimized selection
    always @(*) begin
        select_reg = 16'b0;
        if (address[1:0] == 2'b00)
            select_reg[0] = stage1_out[0];
        else if (address[1:0] == 2'b01)
            select_reg[4] = stage1_out[1];
        else if (address[1:0] == 2'b10)
            select_reg[8] = stage1_out[2];
        else if (address[1:0] == 2'b11)
            select_reg[12] = stage1_out[3];
    end
    
    // Req-Ack handshake control
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            select <= 16'b0;
            ack <= 1'b0;
        end else begin
            if (req) begin
                select <= select_reg;
                ack <= 1'b1;
            end else begin
                ack <= 1'b0;
            end
        end
    end
endmodule