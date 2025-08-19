//SystemVerilog
module ser2par #(parameter WIDTH=8) (
    input clk,
    input en,
    input ser_in,
    output reg [WIDTH-1:0] par_out
);
    reg [WIDTH-1:0] shift_reg;

    always @(posedge clk) begin
        if (en) begin
            shift_reg <= {shift_reg[WIDTH-2:0], ser_in};
            if (shift_reg == (WIDTH-1)) begin
                par_out <= shift_reg;
            end else begin
                par_out <= par_out;
            end
        end
    end
endmodule