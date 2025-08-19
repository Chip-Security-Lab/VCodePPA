module multi_stage_xnor (data_a, data_b, result);
    input wire [3:0] data_a, data_b;
    output wire [3:0] result;

    assign result[0] = ~(data_a[0] ^ data_b[0]);
    assign result[1] = ~(data_a[1] ^ data_b[1]);
    assign result[2] = ~(data_a[2] ^ data_b[2]);
    assign result[3] = ~(data_a[3] ^ data_b[3]);
endmodule