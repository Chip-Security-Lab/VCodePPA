module crossbar_async_4x4 (
    input wire [7:0] data_in_0, data_in_1, data_in_2, data_in_3,
    input wire [1:0] select_out_0, select_out_1, select_out_2, select_out_3,
    output wire [7:0] data_out_0, data_out_1, data_out_2, data_out_3
);
    // Pure combinational implementation without clock
    wire [7:0] input_array [0:3];
    assign input_array[0] = data_in_0;
    assign input_array[1] = data_in_1;
    assign input_array[2] = data_in_2;
    assign input_array[3] = data_in_3;
    
    // Multiplexers for each output
    assign data_out_0 = input_array[select_out_0];
    assign data_out_1 = input_array[select_out_1];
    assign data_out_2 = input_array[select_out_2];
    assign data_out_3 = input_array[select_out_3];
endmodule