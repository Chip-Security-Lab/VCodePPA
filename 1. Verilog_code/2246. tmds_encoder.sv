module tmds_encoder (
    input [7:0] pixel_data,
    input hsync, vsync, active,
    output reg [9:0] encoded
);
    wire [3:0] ones = ^pixel_data;
    always @(*) begin
        case({active, (ones > 4'd4 || (ones == 4'd4 && !pixel_data[0]))})
            2'b11 : encoded = {~pixel_data[7], pixel_data[6:0] ^ {7{pixel_data[7]}}};
            2'b10 : encoded = {2'b01, hsync, vsync, 6'b000000};
            default: encoded = 10'b1101010100;
        endcase
    end
endmodule