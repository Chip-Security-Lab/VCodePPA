module P2S_Converter #(parameter WIDTH=8) (
    input clk, load,
    input [WIDTH-1:0] parallel_in,
    output reg serial_out
);
reg [WIDTH-1:0] buffer;
reg [3:0] count = 0;

always @(posedge clk) begin
    if (load) begin
        buffer <= parallel_in;
        count <= WIDTH-1;
    end else if (count > 0) begin
        serial_out <= buffer[count];
        count <= count - 1;
    end
end
endmodule
