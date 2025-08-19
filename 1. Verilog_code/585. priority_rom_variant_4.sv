//SystemVerilog
module priority_rom (
    input clk,
    input [3:0] addr_high,
    input [3:0] addr_low,
    input high_priority,
    output reg [7:0] data
);
    reg [7:0] rom [0:15];
    reg [3:0] addr_sel;
    reg [7:0] multiplier_a;
    reg [7:0] multiplier_b;
    reg [15:0] product;
    reg [3:0] shift_counter;
    reg [15:0] accumulator;

    initial begin
        rom[0] = 8'h55; rom[1] = 8'h66;
    end

    always @(*) begin
        addr_sel = high_priority ? addr_high : addr_low;
    end

    always @(posedge clk) begin
        data <= rom[addr_sel];
        multiplier_a <= rom[addr_sel];
        multiplier_b <= 8'h02; // Example multiplier value
        shift_counter <= 4'd0;
        accumulator <= 16'd0;
    end

    always @(posedge clk) begin
        if (shift_counter < 4'd8) begin
            if (multiplier_b[shift_counter]) begin
                accumulator <= accumulator + (multiplier_a << shift_counter);
            end
            shift_counter <= shift_counter + 1;
        end else begin
            product <= accumulator;
            shift_counter <= 4'd0;
            accumulator <= 16'd0;
        end
    end
endmodule