module thermometer_encoder(
    input [2:0] bin,
    output [7:0] th_code
);
    assign th_code = (1 << bin) - 1;  // 移位操作实现
endmodule