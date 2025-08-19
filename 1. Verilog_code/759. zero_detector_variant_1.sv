//SystemVerilog
module zero_detector #(
    parameter WIDTH = 12
)(
    input [WIDTH-1:0] data_bus,
    output zero_flag,
    output non_zero_flag,
    output [3:0] leading_zeros
);

    // Zero and non-zero detection
    assign zero_flag = (data_bus == {WIDTH{1'b0}});
    assign non_zero_flag = |data_bus;

    // LUT-based leading zeros counter
    reg [3:0] lz_count;
    wire [3:0] lut_out;
    
    // 4-bit LUT for leading zeros
    leading_zeros_lut lut_inst (
        .data_in(data_bus[WIDTH-1:WIDTH-4]),
        .lz_count(lut_out)
    );

    always @(*) begin
        if (data_bus[WIDTH-1:WIDTH-4] != 4'b0000) begin
            lz_count = lut_out;
        end else if (data_bus[WIDTH-5:WIDTH-8] != 4'b0000) begin
            lz_count = lut_out + 4'd4;
        end else if (data_bus[WIDTH-9:WIDTH-12] != 4'b0000) begin
            lz_count = lut_out + 4'd8;
        end else begin
            lz_count = (WIDTH > 12) ? 4'd12 : WIDTH[3:0];
        end
    end

    assign leading_zeros = lz_count;

endmodule

module leading_zeros_lut (
    input [3:0] data_in,
    output reg [3:0] lz_count
);

    always @(*) begin
        case (data_in)
            4'b0000: lz_count = 4'd4;
            4'b0001: lz_count = 4'd3;
            4'b0010: lz_count = 4'd3;
            4'b0011: lz_count = 4'd2;
            4'b0100: lz_count = 4'd3;
            4'b0101: lz_count = 4'd2;
            4'b0110: lz_count = 4'd2;
            4'b0111: lz_count = 4'd1;
            4'b1000: lz_count = 4'd3;
            4'b1001: lz_count = 4'd2;
            4'b1010: lz_count = 4'd2;
            4'b1011: lz_count = 4'd1;
            4'b1100: lz_count = 4'd2;
            4'b1101: lz_count = 4'd1;
            4'b1110: lz_count = 4'd1;
            4'b1111: lz_count = 4'd0;
        endcase
    end

endmodule