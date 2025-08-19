module rgb_async_convert (
    input [23:0] rgb888,
    output [15:0] rgb565
);
assign rgb565 = {rgb888[23:19],  // R
                 rgb888[15:10],  // G 
                 rgb888[7:3]};    // B
endmodule