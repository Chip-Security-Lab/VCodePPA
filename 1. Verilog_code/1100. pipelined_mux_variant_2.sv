//SystemVerilog
module pipelined_mux (
    input wire clk,                     // System clock
    input wire [1:0] address,           // Selection address
    input wire [15:0] data_0, data_1, data_2, data_3, // Data inputs
    output reg [15:0] result            // Registered result
);

    reg [15:0] mux_out_reg;             // Registered mux output

    wire [15:0] mux_out_comb;           // Combinational mux output

    assign mux_out_comb = (address == 2'b00) ? data_0 :
                          (address == 2'b01) ? data_1 :
                          (address == 2'b10) ? data_2 :
                          (address == 2'b11) ? data_3 :
                          16'b0;

    always @(posedge clk) begin
        mux_out_reg <= mux_out_comb;
    end

    always @(posedge clk) begin
        result <= mux_out_reg;
    end

endmodule