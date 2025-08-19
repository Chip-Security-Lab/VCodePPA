//SystemVerilog
module shift_control(
    input [31:0] data,
    input [4:0] shift_amount,
    input direction,
    output reg [31:0] shifted_data
);
    always @(*) begin
        if (direction) begin
            shifted_data = data >> shift_amount;
        end else begin
            shifted_data = data << shift_amount;
        end
    end
endmodule

module shift_validation(
    input [31:0] data,
    input [4:0] shift_amount,
    output reg [31:0] validated_data
);
    always @(*) begin
        if (shift_amount > 31) begin
            validated_data = 32'b0;
        end else begin
            validated_data = data;
        end
    end
endmodule

module bidirectional_shifter(
    input [31:0] data,
    input [4:0] shift_amount,
    input direction,
    output [31:0] result
);
    wire [31:0] validated_data;
    wire [31:0] shifted_data;

    shift_validation u_validation(
        .data(data),
        .shift_amount(shift_amount),
        .validated_data(validated_data)
    );

    shift_control u_control(
        .data(validated_data),
        .shift_amount(shift_amount),
        .direction(direction),
        .shifted_data(shifted_data)
    );

    assign result = shifted_data;
endmodule