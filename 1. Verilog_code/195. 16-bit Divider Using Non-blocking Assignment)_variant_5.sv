//SystemVerilog
module divider_16bit_nba (
    input wire clk,
    input wire rst_n,
    input wire [15:0] dividend,
    input wire [15:0] divisor,
    output reg [15:0] quotient,
    output reg [15:0] remainder
);

// Pipeline stage registers
reg [15:0] dividend_reg;
reg [15:0] divisor_reg;
reg [15:0] quotient_reg;
reg [15:0] remainder_reg;

// Control signals
reg calc_start;
reg calc_done;

// State machine states
localparam IDLE = 2'b00;
localparam CALC = 2'b01;
localparam DONE = 2'b10;
reg [1:0] state;

// Pipeline stages
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        state <= IDLE;
        dividend_reg <= 16'b0;
        divisor_reg <= 16'b0;
        quotient_reg <= 16'b0;
        remainder_reg <= 16'b0;
        calc_start <= 1'b0;
        calc_done <= 1'b0;
    end else begin
        case (state)
            IDLE: begin
                dividend_reg <= dividend;
                divisor_reg <= divisor;
                calc_start <= 1'b1;
                state <= CALC;
            end
            CALC: begin
                if (calc_start) begin
                    quotient_reg <= dividend_reg / divisor_reg;
                    remainder_reg <= dividend_reg % divisor_reg;
                    calc_done <= 1'b1;
                    state <= DONE;
                end
            end
            DONE: begin
                quotient <= quotient_reg;
                remainder <= remainder_reg;
                calc_done <= 1'b0;
                state <= IDLE;
            end
        endcase
    end
end

endmodule