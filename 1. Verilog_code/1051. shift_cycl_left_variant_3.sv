//SystemVerilog
module shift_cycl_left #(parameter WIDTH=8) (
    input wire clk,
    input wire rst_n,
    input wire en,
    input wire [WIDTH-1:0] data_in,
    output wire [WIDTH-1:0] data_out
);

reg [WIDTH-1:0] data_reg;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        data_reg <= {WIDTH{1'b0}};
    end else if (en) begin
        data_reg <= data_in;
    end
end

assign data_out = (WIDTH == 1) ? data_reg : {data_reg[WIDTH-2:0], data_reg[WIDTH-1]};

endmodule