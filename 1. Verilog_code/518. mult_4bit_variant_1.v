module booth_mult_8bit(
    input [7:0] a,
    input [7:0] b,
    output [15:0] prod
);

    // 内部信号
    wire [15:0] partial_prod;
    wire [7:0] multiplicand;
    wire [8:0] multiplier;
    wire [3:0] count;

    // 实例化控制单元
    booth_control_unit control_unit(
        .a(a),
        .b(b),
        .multiplicand(multiplicand),
        .multiplier(multiplier),
        .count(count)
    );

    // 实例化计算单元
    booth_calc_unit calc_unit(
        .multiplicand(multiplicand),
        .multiplier(multiplier),
        .count(count),
        .partial_prod(partial_prod)
    );

    assign prod = partial_prod;

endmodule

module booth_control_unit(
    input [7:0] a,
    input [7:0] b,
    output reg [7:0] multiplicand,
    output reg [8:0] multiplier,
    output reg [3:0] count
);

    always @(*) begin
        multiplicand = a;
        multiplier = {b, 1'b0};
        count = 4'b0;
    end

endmodule

module booth_calc_unit(
    input [7:0] multiplicand,
    input [8:0] multiplier,
    input [3:0] count,
    output reg [15:0] partial_prod
);

    reg [7:0] temp_multiplicand;
    reg [8:0] temp_multiplier;
    reg [3:0] temp_count;

    always @(*) begin
        temp_multiplicand = multiplicand;
        temp_multiplier = multiplier;
        temp_count = count;
        partial_prod = 16'b0;

        for(temp_count = 0; temp_count < 8; temp_count = temp_count + 1) begin
            if (temp_multiplier[1:0] == 2'b01) begin
                partial_prod = partial_prod + temp_multiplicand;
            end else if (temp_multiplier[1:0] == 2'b10) begin
                partial_prod = partial_prod - temp_multiplicand;
            end
            
            temp_multiplicand = temp_multiplicand << 1;
            temp_multiplier = temp_multiplier >> 1;
        end
    end

endmodule