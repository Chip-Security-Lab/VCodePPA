//SystemVerilog
module MuxLatch #(
    parameter DATA_WIDTH = 4,
    parameter SEL_WIDTH = 2
) (
    input wire clk,
    input wire [2**SEL_WIDTH-1:0][DATA_WIDTH-1:0] data_in,
    input wire [SEL_WIDTH-1:0] select,
    output reg [DATA_WIDTH-1:0] data_out
);

    reg [2**SEL_WIDTH-1:0][DATA_WIDTH-1:0] data_in_reg;
    reg [SEL_WIDTH-1:0] select_reg;
    reg [DATA_WIDTH-1:0] mux_out_reg;

    always @(posedge clk) begin
        data_in_reg <= data_in;
        select_reg <= select;
        mux_out_reg <= data_in_reg[select_reg];
        data_out <= mux_out_reg;
    end

endmodule