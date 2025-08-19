//SystemVerilog
module async_rst_rotator (
    input clk, arst, en,
    input [7:0] data_in,
    input [2:0] shift,
    output reg [7:0] data_out
);
    reg [7:0] shift_left, shift_right;
    reg [7:0] subtrahend;
    reg [8:0] diff;
    reg borrow;
    reg [7:0] rotated_data;
    
    always @(*) begin
        shift_left = data_in << shift;
        shift_right = data_in >> (8 - shift);
        subtrahend = ~shift_right;
        {borrow, diff[7:0]} = shift_left + subtrahend + 1'b1;
        
        // 预先计算旋转后的数据，减少后续逻辑层级
        rotated_data = shift_left | shift_right;
    end
    
    always @(posedge clk or posedge arst) begin
        if (arst) begin
            data_out <= 8'h0;
        end
        else if (en) begin
            case (shift)
                3'h0:    data_out <= data_in;
                default: data_out <= rotated_data;
            endcase
        end
    end
endmodule