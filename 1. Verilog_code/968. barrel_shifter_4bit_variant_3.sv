//SystemVerilog
module barrel_shifter_4bit (
    input [3:0] data_in,
    input [1:0] shift_amount,
    input direction,  // 0: right, 1: left
    output reg [3:0] data_out
);

    // Shift and accumulate logic
    always @(*) begin
        if (direction) begin // Left shift
            case(shift_amount)
                2'b00: data_out = data_in;
                2'b01: data_out = {data_in[2:0], 1'b0};
                2'b10: data_out = {data_in[1:0], 2'b00};
                2'b11: data_out = {data_in[0], 3'b000};
            endcase
        end
        else begin // Right shift
            case(shift_amount)
                2'b00: data_out = data_in;
                2'b01: data_out = {1'b0, data_in[3:1]};
                2'b10: data_out = {2'b00, data_in[3:2]};
                2'b11: data_out = {3'b000, data_in[3]};
            endcase
        end
    end
endmodule