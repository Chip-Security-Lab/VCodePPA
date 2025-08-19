//SystemVerilog
module zero_detector #(
    parameter WIDTH = 12
)(
    input [WIDTH-1:0] data_bus,
    output zero_flag,
    output non_zero_flag,
    output [3:0] leading_zeros
);

    // Zero detection using NOR reduction
    assign zero_flag = ~(|data_bus);
    
    // Non-zero detection using OR reduction
    assign non_zero_flag = |data_bus;
    
    // Binary search based leading zeros counter
    reg [3:0] lz_count;
    wire [WIDTH-1:0] has_one;
    
    // Binary search priority encoder
    generate
        if (WIDTH <= 16) begin : gen_bs_encoder
            always @(*) begin
                casez (data_bus)
                    16'b1???????????????: lz_count = 4'd0;
                    16'b01??????????????: lz_count = 4'd1;
                    16'b001?????????????: lz_count = 4'd2;
                    16'b0001????????????: lz_count = 4'd3;
                    16'b00001???????????: lz_count = 4'd4;
                    16'b000001??????????: lz_count = 4'd5;
                    16'b0000001?????????: lz_count = 4'd6;
                    16'b00000001????????: lz_count = 4'd7;
                    16'b000000001???????: lz_count = 4'd8;
                    16'b0000000001??????: lz_count = 4'd9;
                    16'b00000000001?????: lz_count = 4'd10;
                    16'b000000000001????: lz_count = 4'd11;
                    16'b0000000000001???: lz_count = 4'd12;
                    16'b00000000000001??: lz_count = 4'd13;
                    16'b000000000000001?: lz_count = 4'd14;
                    16'b0000000000000001: lz_count = 4'd15;
                    default: lz_count = (WIDTH > 15) ? 4'd15 : WIDTH[3:0];
                endcase
            end
        end
    endgenerate
    
    assign leading_zeros = lz_count;
endmodule