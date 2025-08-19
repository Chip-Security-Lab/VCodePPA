module zero_detector #(
    parameter WIDTH = 12
)(
    input [WIDTH-1:0] data_bus,
    output zero_flag,            // High when all bits are zero
    output non_zero_flag,        // High when any bit is one
    output [3:0] leading_zeros   // Count of leading zeros (MSB side)
);
    // Detect if all bits are zero
    assign zero_flag = (data_bus == {WIDTH{1'b0}});
    
    // Detect if any bit is one
    assign non_zero_flag = |data_bus;
    
    // Count leading zeros - 改进的方法
    reg [3:0] lz_count;
    
    always @(*) begin
        lz_count = 4'd0;
        if (data_bus[WIDTH-1]) lz_count = 4'd0;
        else if (data_bus[WIDTH-2]) lz_count = 4'd1;
        else if (data_bus[WIDTH-3]) lz_count = 4'd2;
        else if (data_bus[WIDTH-4]) lz_count = 4'd3;
        else if (data_bus[WIDTH-5]) lz_count = 4'd4;
        else if (data_bus[WIDTH-6]) lz_count = 4'd5;
        else if (data_bus[WIDTH-7]) lz_count = 4'd6;
        else if (data_bus[WIDTH-8]) lz_count = 4'd7;
        else if (data_bus[WIDTH-9]) lz_count = 4'd8;
        else if (data_bus[WIDTH-10]) lz_count = 4'd9;
        else if (data_bus[WIDTH-11]) lz_count = 4'd10;
        else if (WIDTH > 11 && data_bus[WIDTH-12]) lz_count = 4'd11;
        else if (WIDTH > 12 && data_bus[WIDTH-13]) lz_count = 4'd12;
        else if (WIDTH > 13 && data_bus[WIDTH-14]) lz_count = 4'd13;
        else if (WIDTH > 14 && data_bus[WIDTH-15]) lz_count = 4'd14;
        else lz_count = (WIDTH > 15) ? 4'd15 : WIDTH[3:0];
    end
    
    assign leading_zeros = lz_count;
endmodule