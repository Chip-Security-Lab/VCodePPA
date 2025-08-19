//SystemVerilog
module two_stage_decoder_req_ack (
    input clk,
    input rst_n,
    input [3:0] address,
    input req,
    output reg ack,
    output reg [15:0] select
);

    reg [3:0] stage1_out;
    reg [3:0] address_reg;
    reg req_reg;
    wire [1:0] addr_low;
    wire [1:0] addr_high;
    
    assign addr_low = address_reg[1:0];
    assign addr_high = address_reg[3:2];
    
    // First stage decodes top 2 bits
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage1_out <= 4'b0;
            address_reg <= 4'b0;
            req_reg <= 1'b0;
            ack <= 1'b0;
            select <= 16'b0;
        end else begin
            req_reg <= req;
            
            if (req && !req_reg) begin
                address_reg <= address;
                stage1_out <= (4'b0001 << addr_high);
                ack <= 1'b1;
            end else if (!req) begin
                ack <= 1'b0;
            end
            
            if (ack) begin
                select <= (16'b0001 << {addr_high, addr_low});
            end
        end
    end

endmodule