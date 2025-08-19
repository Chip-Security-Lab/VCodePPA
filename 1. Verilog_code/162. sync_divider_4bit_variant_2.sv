//SystemVerilog
module sync_divider_4bit (
    input clk,
    input reset,
    input valid,
    output reg ready,
    input [3:0] a,
    input [3:0] b,
    output reg [3:0] quotient,
    output reg quotient_valid
);

    // Pipeline registers
    reg [3:0] a_reg, b_reg;
    reg [3:0] partial_quotient;
    reg [3:0] remainder;
    reg [1:0] state;
    
    localparam IDLE = 2'b00;
    localparam COMPUTE = 2'b01;
    localparam OUTPUT = 2'b10;
    
    // Stage 1: Input registration
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            a_reg <= 4'b0;
            b_reg <= 4'b0;
            state <= IDLE;
            ready <= 1'b1;
            quotient_valid <= 1'b0;
        end else begin
            case(state)
                IDLE: begin
                    if (valid && ready) begin
                        a_reg <= a;
                        b_reg <= b;
                        state <= COMPUTE;
                        ready <= 1'b0;
                    end
                end
                COMPUTE: begin
                    if (b_reg != 4'b0) begin
                        partial_quotient <= a_reg / b_reg;
                        remainder <= a_reg % b_reg;
                    end else begin
                        partial_quotient <= 4'b0;
                        remainder <= 4'b0;
                    end
                    state <= OUTPUT;
                end
                OUTPUT: begin
                    quotient <= partial_quotient;
                    quotient_valid <= 1'b1;
                    state <= IDLE;
                    ready <= 1'b1;
                end
            endcase
        end
    end

endmodule