//SystemVerilog
module fibonacci_lfsr #(parameter WIDTH = 8) (
    input wire clk,
    input wire rst_n,
    input wire enable,
    input wire [WIDTH-1:0] seed,
    input wire [WIDTH-1:0] polynomial,  // Taps as '1' bits
    output wire [WIDTH-1:0] lfsr_out,
    output wire serial_out
);

    reg [WIDTH-1:0] lfsr_reg;
    reg [WIDTH-1:0] lfsr_out_reg;
    reg serial_out_reg;

    wire feedback;

    assign feedback = ^(lfsr_reg & polynomial);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            lfsr_reg      <= seed;
            lfsr_out_reg  <= seed;
            serial_out_reg <= seed[0];
        end else begin
            if (enable) begin
                lfsr_reg      <= {feedback, lfsr_reg[WIDTH-1:1]};
                lfsr_out_reg  <= {feedback, lfsr_reg[WIDTH-1:1]};
                serial_out_reg <= feedback;
            end else begin
                lfsr_reg      <= lfsr_reg;
                lfsr_out_reg  <= lfsr_reg;
                serial_out_reg <= lfsr_reg[0];
            end
        end
    end

    assign lfsr_out = lfsr_out_reg;
    assign serial_out = serial_out_reg;

endmodule