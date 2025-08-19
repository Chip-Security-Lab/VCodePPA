//SystemVerilog
module barrel_shifter #(parameter WIDTH=8) (
    input  wire [WIDTH-1:0] data,
    input  wire [2:0]       shift,
    output reg  [WIDTH-1:0] result
);
    always @* begin
        case (shift)
            3'd0: result = data;
            3'd1: result = {data[WIDTH-2:0], data[WIDTH-1]};
            3'd2: result = {data[WIDTH-3:0], data[WIDTH-1:WIDTH-2]};
            3'd3: result = {data[WIDTH-4:0], data[WIDTH-1:WIDTH-3]};
            3'd4: result = {data[WIDTH-5:0], data[WIDTH-1:WIDTH-4]};
            3'd5: result = {data[WIDTH-6:0], data[WIDTH-1:WIDTH-5]};
            3'd6: result = {data[WIDTH-7:0], data[WIDTH-1:WIDTH-6]};
            3'd7: result = {data[WIDTH-8:0], data[WIDTH-1:WIDTH-7]};
            default: result = data;
        endcase
    end
endmodule