//SystemVerilog
module lsl_shifter(
    input wire clk,
    input wire rst_n,
    input wire en,
    input wire [7:0] data_in,
    input wire [2:0] shift_amt,
    output reg [7:0] data_out
);
    wire [7:0] shift_0;
    wire [7:0] shift_1;
    wire [7:0] shift_2;
    wire [7:0] shift_3;
    wire [7:0] shift_4;
    wire [7:0] shift_5;
    wire [7:0] shift_6;
    wire [7:0] shift_7;
    wire [7:0] mux_level0_a, mux_level0_b, mux_level1;

    // Precompute all possible shift results (constant logic depth)
    assign shift_0 = data_in;
    assign shift_1 = {data_in[6:0], 1'b0};
    assign shift_2 = {data_in[5:0], 2'b00};
    assign shift_3 = {data_in[4:0], 3'b000};
    assign shift_4 = {data_in[3:0], 4'b0000};
    assign shift_5 = {data_in[2:0], 5'b00000};
    assign shift_6 = {data_in[1:0], 6'b000000};
    assign shift_7 = {data_in[0], 7'b0000000};

    // Balanced 3-level multiplexer tree for path balancing
    assign mux_level0_a = (shift_amt[1:0] == 2'b00) ? shift_0 :
                          (shift_amt[1:0] == 2'b01) ? shift_1 :
                          (shift_amt[1:0] == 2'b10) ? shift_2 :
                                                      shift_3;

    assign mux_level0_b = (shift_amt[1:0] == 2'b00) ? shift_4 :
                          (shift_amt[1:0] == 2'b01) ? shift_5 :
                          (shift_amt[1:0] == 2'b10) ? shift_6 :
                                                      shift_7;

    assign mux_level1 = shift_amt[2] ? mux_level0_b : mux_level0_a;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            data_out <= 8'b0;
        else if (en)
            data_out <= mux_level1;
    end
endmodule