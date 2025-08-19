//SystemVerilog
module ror_module #(
    parameter WIDTH = 8
)(
    input wire clk,
    input wire rst,
    input wire en,
    input wire [WIDTH-1:0] data_in,
    input wire [$clog2(WIDTH)-1:0] rotate_by,
    output reg [WIDTH-1:0] data_out
);

    reg [WIDTH-1:0] data_in_reg;
    reg [$clog2(WIDTH)-1:0] rotate_by_reg;

    wire [WIDTH-1:0] rotated_result;

    assign rotated_result = {data_in_reg, data_in_reg} >> rotate_by_reg;

    always @(posedge clk) begin
        if (rst) begin
            data_in_reg    <= {WIDTH{1'b0}};
            rotate_by_reg  <= {($clog2(WIDTH)){1'b0}};
            data_out       <= {WIDTH{1'b0}};
        end else if (en) begin
            data_in_reg    <= data_in;
            rotate_by_reg  <= rotate_by;
            data_out       <= rotated_result;
        end
    end

endmodule