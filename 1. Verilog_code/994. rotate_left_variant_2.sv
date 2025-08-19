//SystemVerilog
module rotate_left(
    input [31:0] data,
    input [4:0] amount,
    output [31:0] result
);
    assign result = (data << amount) | (data >> (32 - amount));
endmodule

module ror_module #(
    parameter WIDTH = 8
)(
    input clk,
    input rst,
    input en,
    input [WIDTH-1:0] data_in,
    input [$clog2(WIDTH)-1:0] rotate_by,
    output [WIDTH-1:0] data_out
);

    reg [WIDTH-1:0] data_in_reg;
    reg [$clog2(WIDTH)-1:0] rotate_by_reg;
    reg en_reg;

    // Pipeline stage: Register the inputs
    always @(posedge clk) begin
        if (rst) begin
            data_in_reg <= {WIDTH{1'b0}};
            rotate_by_reg <= {$clog2(WIDTH){1'b0}};
            en_reg <= 1'b0;
        end else begin
            data_in_reg <= data_in;
            rotate_by_reg <= rotate_by;
            en_reg <= en;
        end
    end

    // Pipeline stage: Register the output after combinational logic
    reg [WIDTH-1:0] rotate_result;

    always @* begin
        rotate_result = ({data_in_reg, data_in_reg} >> rotate_by_reg);
    end

    reg [WIDTH-1:0] data_out_reg;

    always @(posedge clk) begin
        if (rst) begin
            data_out_reg <= {WIDTH{1'b0}};
        end else if (en_reg) begin
            data_out_reg <= rotate_result;
        end
    end

    assign data_out = data_out_reg;

endmodule