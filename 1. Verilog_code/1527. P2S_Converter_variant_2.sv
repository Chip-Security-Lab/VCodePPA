//SystemVerilog
// IEEE 1364-2005
module P2S_Converter #(parameter WIDTH=8) (
    input clk, load,
    input [WIDTH-1:0] parallel_in,
    output reg serial_out
);
    reg [WIDTH-1:0] buffer;
    reg [3:0] count;
    reg serial_out_next;
    
    always @(*) begin
        if (load)
            serial_out_next = parallel_in[WIDTH-1];
        else if (|count)
            serial_out_next = buffer[count-1];
        else
            serial_out_next = serial_out;
    end
    
    always @(posedge clk) begin
        serial_out <= serial_out_next;
        
        if (load) begin
            buffer <= parallel_in;
            count <= WIDTH-1;
        end else if (|count) begin
            count <= count - 1'b1;  // 直接使用减法运算符，更易综合
        end
    end
endmodule