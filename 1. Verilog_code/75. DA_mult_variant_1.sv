//SystemVerilog
module DA_mult (
    input clk,
    input rst_n,
    input req,
    output reg ack,
    input [3:0] x,
    input [3:0] y,
    output reg [7:0] out,
    output reg out_valid
);

    reg [3:0] x_reg;
    reg [3:0] y_reg;
    reg [7:0] result_reg;
    reg processing;
    reg req_reg;
    
    wire [3:0] pp0, pp1, pp2, pp3;
    
    assign pp0 = y_reg[0] ? x_reg : 4'b0000;
    assign pp1 = y_reg[1] ? x_reg : 4'b0000;
    assign pp2 = y_reg[2] ? x_reg : 4'b0000;
    assign pp3 = y_reg[3] ? x_reg : 4'b0000;
    
    wire [7:0] shifted_pp1 = {pp1, 1'b0};
    wire [7:0] shifted_pp2 = {pp2, 2'b00};
    wire [7:0] shifted_pp3 = {pp3, 3'b000};
    
    wire [7:0] result = {4'b0000, pp0} + shifted_pp1 + shifted_pp2 + shifted_pp3;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ack <= 1'b0;
            out_valid <= 1'b0;
            processing <= 1'b0;
            x_reg <= 4'b0;
            y_reg <= 4'b0;
            result_reg <= 8'b0;
            req_reg <= 1'b0;
        end else begin
            req_reg <= req;
            
            if (req && !req_reg && !processing) begin
                x_reg <= x;
                y_reg <= y;
                processing <= 1'b1;
                ack <= 1'b1;
            end
            
            if (processing) begin
                result_reg <= result;
                out_valid <= 1'b1;
                processing <= 1'b0;
                ack <= 1'b0;
            end else begin
                out_valid <= 1'b0;
            end
        end
    end
    
    assign out = result_reg;
    
endmodule