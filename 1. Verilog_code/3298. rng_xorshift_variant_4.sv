//SystemVerilog
module rng_xorshift_18(
    input             clk,
    input             rst,
    input             en,
    output reg [7:0]  data_o
);
    reg [7:0] x_reg = 8'hAA;
    reg [7:0] x_next;

    always @* begin
        case ({rst, en})
            2'b10: x_next = 8'hAA;
            2'b01: begin
                x_next = x_reg ^ (x_reg << 3);
                x_next = x_next ^ (x_next >> 2);
                x_next = x_next ^ (x_next << 1);
            end
            default: x_next = x_reg;
        endcase
    end

    always @(posedge clk) begin
        x_reg <= x_next;
        data_o <= x_next;
    end
endmodule