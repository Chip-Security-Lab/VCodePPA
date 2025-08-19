//SystemVerilog
module width_expander #(
    parameter IN_WIDTH = 8,
    parameter OUT_WIDTH = 32  // 必须是IN_WIDTH的整数倍
)(
    input clk,
    input rst,
    input valid_in,
    input [IN_WIDTH-1:0] data_in,
    output reg [OUT_WIDTH-1:0] data_out,
    output reg valid_out
);
    localparam RATIO = OUT_WIDTH / IN_WIDTH;
    reg [$clog2(RATIO)-1:0] data_count;
    reg [OUT_WIDTH-1:0] data_buffer;

    // 32-bit two's complement adder for subtraction
    function [31:0] subtract_32bit;
        input [31:0] minuend;
        input [31:0] subtrahend;
        begin
            subtract_32bit = minuend + (~subtrahend + 32'b1);
        end
    endfunction

    always @(posedge clk) begin
        if (rst) begin
            data_count <= 0;
            data_buffer <= 0;
            valid_out <= 0;
            data_out <= 0;
        end else if (valid_in) begin
            data_buffer <= {data_buffer[OUT_WIDTH-IN_WIDTH-1:0], data_in};
            if (data_count == subtract_32bit(RATIO, 32'd1)) begin
                data_count <= 0;
                data_out <= {data_buffer[OUT_WIDTH-IN_WIDTH-1:0], data_in};
                valid_out <= 1;
            end else begin
                data_count <= data_count + 1;
                valid_out <= 0;
            end
        end else begin
            valid_out <= 0;
        end
    end
endmodule