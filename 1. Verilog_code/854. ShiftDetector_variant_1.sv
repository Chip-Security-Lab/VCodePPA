//SystemVerilog
// SystemVerilog
module ShiftDetector #(parameter WIDTH=8) (
    input clk, rst_n,
    input data_in,
    output reg sequence_found
);
    localparam PATTERN = 8'b11010010;
    reg [WIDTH-1:0] shift_reg;
    reg pattern_match_high, pattern_match_low;
    wire pattern_match;

    // Shift register update logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            shift_reg <= '0;
        end
        else begin
            shift_reg <= {shift_reg[WIDTH-2:0], data_in};
        end
    end

    // High nibble pattern matching logic
    always @(*) begin
        pattern_match_high = (shift_reg[7:4] == PATTERN[7:4]);
    end

    // Low nibble pattern matching logic
    always @(*) begin
        pattern_match_low = (shift_reg[3:0] == PATTERN[3:0]);
    end

    // Combine pattern matching results
    assign pattern_match = pattern_match_high && pattern_match_low;

    // Sequence detection output logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sequence_found <= 1'b0;
        end
        else begin
            sequence_found <= pattern_match;
        end
    end
endmodule