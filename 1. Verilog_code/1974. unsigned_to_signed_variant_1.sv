//SystemVerilog
module unsigned_to_signed #(parameter WIDTH=16)(
    input wire [WIDTH-1:0] unsigned_in,
    output reg [WIDTH-1:0] signed_out,
    output reg overflow
);
    wire [WIDTH-2:0] operand_b;
    wire subtract_en;
    wire [WIDTH-2:0] add_result;
    wire carry_out;
    reg [WIDTH-2:0] input_data;

    assign subtract_en = unsigned_in[WIDTH-1];
    assign operand_b = {WIDTH-1{1'b1}};

    always @* begin
        if (subtract_en) begin
            input_data = ~unsigned_in[WIDTH-2:0];
        end else begin
            input_data = unsigned_in[WIDTH-2:0];
        end
    end

    assign {carry_out, add_result} = input_data + subtract_en;

    always @* begin
        if (subtract_en) begin
            overflow = 1'b1;
            signed_out = {1'b0, add_result};
        end else begin
            overflow = 1'b0;
            signed_out = unsigned_in;
        end
    end
endmodule