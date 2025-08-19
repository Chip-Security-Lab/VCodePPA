//SystemVerilog
module FaultTolerantArbiter (
    input clk, rst,
    input [3:0] req,
    output [3:0] grant
);
    reg [3:0] grant_a, grant_b;
    reg grant_valid;
    
    ArbiterBase3 arb_a (.clk(clk), .rst(rst), .req(req), .grant(grant_a));
    ArbiterBase3 arb_b (.clk(clk), .rst(rst), .req(req), .grant(grant_b));
    
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            grant_valid <= 1'b0;
        end else begin
            grant_valid <= (grant_a == grant_b);
        end
    end
    
    assign grant = grant_valid ? grant_a : 4'b0000;
endmodule

module ArbiterBase3 (
    input clk, rst,
    input [3:0] req,
    output reg [3:0] grant
);
    reg [1:0] priority_state;
    reg [3:0] req_reg;
    
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            req_reg <= 4'b0000;
            grant <= 4'b0000;
            priority_state <= 2'b00;
        end else begin
            req_reg <= req;
            case (priority_state)
                2'b00: begin
                    grant <= req_reg[0] ? 4'b0001 : 
                            req_reg[1] ? 4'b0010 : 
                            req_reg[2] ? 4'b0100 : 
                            req_reg[3] ? 4'b1000 : 4'b0000;
                    priority_state <= 2'b01;
                end
                2'b01: begin
                    grant <= req_reg[1] ? 4'b0010 : 
                            req_reg[2] ? 4'b0100 : 
                            req_reg[3] ? 4'b1000 : 
                            req_reg[0] ? 4'b0001 : 4'b0000;
                    priority_state <= 2'b10;
                end
                2'b10: begin
                    grant <= req_reg[2] ? 4'b0100 : 
                            req_reg[3] ? 4'b1000 : 
                            req_reg[0] ? 4'b0001 : 
                            req_reg[1] ? 4'b0010 : 4'b0000;
                    priority_state <= 2'b11;
                end
                2'b11: begin
                    grant <= req_reg[3] ? 4'b1000 : 
                            req_reg[0] ? 4'b0001 : 
                            req_reg[1] ? 4'b0010 : 
                            req_reg[2] ? 4'b0100 : 4'b0000;
                    priority_state <= 2'b00;
                end
            endcase
        end
    end
endmodule