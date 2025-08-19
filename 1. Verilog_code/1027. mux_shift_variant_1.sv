//SystemVerilog
module mux_shift #(parameter W=8) (
    input  wire [W-1:0] data_in,
    input  wire [1:0]   sel,
    output reg  [W-1:0] data_out
);

    // Internal signals for 2-bit subtractor using two's complement addition
    wire [1:0] subtrahend;
    wire [1:0] minuend;
    wire [1:0] twos_complement_subtrahend;
    wire [2:0] sum_result;

    // Example: 2-bit subtractor using two's complement adder
    assign minuend = data_in[1:0];
    assign subtrahend = 2'b01; // example: subtract 1
    assign twos_complement_subtrahend = ~subtrahend + 2'b01;
    assign sum_result = {1'b0, minuend} + {1'b0, twos_complement_subtrahend};

    always @* begin
        case (sel)
            2'b00: data_out = data_in;
            2'b01: data_out = {data_in[W-2:0], 1'b0};
            2'b10: data_out = {data_in[W-3:0], 2'b00};
            default: begin
                // Replace subtraction with two's complement addition for lower 2 bits, rest zero
                data_out = { { (W-2){1'b0} }, sum_result[1:0] };
            end
        endcase
    end

endmodule