//SystemVerilog
module lut_rom (
    input clk,
    input rst_n,
    input [3:0] addr,
    input req,
    output reg ack,
    output reg [7:0] data
);

    reg [7:0] data_reg;
    reg ack_reg;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_reg <= 8'h00;
            ack_reg <= 1'b0;
        end else begin
            if (req && !ack_reg) begin
                case (addr)
                    4'h0: data_reg <= 8'hA1;
                    4'h1: data_reg <= 8'hB2;
                    4'h2: data_reg <= 8'hC3;
                    4'h3: data_reg <= 8'hD4;
                    4'h4: data_reg <= 8'hE5;
                    4'h5: data_reg <= 8'hF6;
                    4'h6: data_reg <= 8'h07;
                    4'h7: data_reg <= 8'h18;
                    default: data_reg <= 8'h00;
                endcase
                ack_reg <= 1'b1;
            end else if (!req) begin
                ack_reg <= 1'b0;
            end
        end
    end

    assign data = data_reg;
    assign ack = ack_reg;

endmodule