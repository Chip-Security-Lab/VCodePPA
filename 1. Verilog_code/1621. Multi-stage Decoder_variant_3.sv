//SystemVerilog
module two_stage_decoder (
    input wire clk,
    input wire rst_n,
    input wire valid,
    output wire ready,
    input [3:0] address,
    output reg [15:0] select
);

    reg [3:0] stage1_out;
    reg [15:0] select_reg;
    reg ready_reg;
    
    // First stage decodes top 2 bits
    always @(*) begin
        stage1_out = (4'b0001 << address[3:2]);
    end
    
    // Second stage uses bottom 2 bits
    always @(*) begin
        select_reg[3:0]   = address[1:0] == 2'b00 ? {3'b000, stage1_out[0]} : 4'b0000;
        select_reg[7:4]   = address[1:0] == 2'b01 ? {3'b000, stage1_out[1]} : 4'b0000;
        select_reg[11:8]  = address[1:0] == 2'b10 ? {3'b000, stage1_out[2]} : 4'b0000;
        select_reg[15:12] = address[1:0] == 2'b11 ? {3'b000, stage1_out[3]} : 4'b0000;
    end
    
    // Valid-Ready handshake logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            select <= 16'b0;
            ready_reg <= 1'b0;
        end else begin
            if (valid && ready_reg) begin
                select <= select_reg;
                ready_reg <= 1'b0;
            end else if (!valid) begin
                ready_reg <= 1'b1;
            end
        end
    end
    
    assign ready = ready_reg;
    
endmodule