//SystemVerilog
module shift_thermometer #(parameter WIDTH=8) (
    input  wire                  clk,
    input  wire                  dir,
    output reg  [WIDTH-1:0]      therm
);

    reg [WIDTH-1:0] therm_d;

    // Barrel shifter for right shift by 1 with MSB fill '1'
    wire [WIDTH-1:0] shift_right_result;
    assign shift_right_result = {1'b1, therm_d[WIDTH-1:1]};

    // Barrel shifter for left shift by 1 with LSB fill '1'
    wire [WIDTH-1:0] shift_left_result;
    assign shift_left_result = {therm_d[WIDTH-2:0], 1'b1};

    always @(posedge clk) begin
        therm_d <= therm;
    end

    always @(posedge clk) begin
        if (dir)
            therm <= shift_right_result;
        else
            therm <= shift_left_result;
    end

endmodule