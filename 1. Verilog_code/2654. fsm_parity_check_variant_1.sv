//SystemVerilog
module fsm_parity_check (
    input clk, rst_n,
    input valid,
    input [7:0] data,
    output reg ready,
    output reg parity
);
    parameter IDLE = 1'b0;
    parameter CALC = 1'b1;
    
    reg state;
    reg data_latched;
    reg [7:0] data_reg;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            parity <= 0;
            ready <= 1'b1;
            data_latched <= 1'b0;
            data_reg <= 8'h0;
        end else case(state)
            IDLE: begin
                if (valid && ready) begin
                    data_reg <= data;
                    data_latched <= 1'b1;
                    ready <= 1'b0;
                    state <= CALC;
                end
            end
            CALC: begin
                parity <= ^data_reg;
                ready <= 1'b1;
                data_latched <= 1'b0;
                state <= IDLE;
            end
            default: begin
                state <= IDLE;
                ready <= 1'b1;
            end
        endcase
    end
endmodule