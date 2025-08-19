module async_bridge #(parameter WIDTH=16) (
    input [WIDTH-1:0] a_data,
    input a_valid, b_ready,
    output [WIDTH-1:0] b_data,
    output a_ready, b_valid
);
    assign b_data = a_data;
    assign b_valid = a_valid;
    assign a_ready = b_ready;
endmodule