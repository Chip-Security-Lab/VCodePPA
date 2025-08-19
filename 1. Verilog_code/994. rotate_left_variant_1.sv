//SystemVerilog

module rotate_left(
    input  [31:0] data_in,
    input  [4:0]  shift_amount,
    input         valid_in,
    output [31:0] data_out,
    output        valid_out,
    input         ready_in,
    output        ready_out
);
    reg [31:0] result_reg;
    reg        valid_reg;
    wire       handshake;

    assign handshake = valid_in && ready_out;
    assign data_out  = result_reg;
    assign valid_out = valid_reg;
    assign ready_out = !valid_reg || (valid_reg && ready_in);

    always @(posedge valid_in or posedge ready_in) begin
        if (handshake) begin
            result_reg <= (data_in << shift_amount) | (data_in >> (32 - shift_amount));
            valid_reg  <= 1'b1;
        end else if (valid_reg && ready_in) begin
            valid_reg <= 1'b0;
        end
    end
endmodule

module ror_module #(
    parameter WIDTH = 8
)(
    input                     clk,
    input                     rst,
    input                     valid_in,
    input [WIDTH-1:0]         data_in,
    input [$clog2(WIDTH)-1:0] rotate_by,
    output reg [WIDTH-1:0]    data_out,
    output reg                valid_out,
    input                     ready_in,
    output                    ready_out
);
    wire [WIDTH-1:0] rotated_data;
    reg              valid_reg;

    assign rotated_data = {data_in, data_in} >> rotate_by;
    assign ready_out    = !valid_out || (valid_out && ready_in);

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            data_out  <= {WIDTH{1'b0}};
            valid_out <= 1'b0;
        end else begin
            if (valid_in && ready_out) begin
                data_out  <= rotated_data;
                valid_out <= 1'b1;
            end else if (valid_out && ready_in) begin
                valid_out <= 1'b0;
            end
        end
    end
endmodule