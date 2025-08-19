//SystemVerilog
module timeout_parity #(
    parameter TIMEOUT = 100
)(
    input clk, rst,
    input data_valid,
    input [15:0] data,
    output reg parity,
    output reg timeout
);
reg [$clog2(TIMEOUT)-1:0] counter;
reg [1:0] state;

localparam IDLE = 2'b00;
localparam COUNT = 2'b01;
localparam TIMEOUT_STATE = 2'b10;

always @(posedge clk) begin
    if (rst) begin
        counter <= 0;
        parity <= 0;
        timeout <= 0;
        state <= IDLE;
    end else begin
        case (state)
            IDLE: begin
                if (data_valid) begin
                    parity <= ^data;
                    counter <= 0;
                    timeout <= 0;
                    state <= IDLE;
                end else begin
                    counter <= counter + 1;
                    state <= COUNT;
                end
            end
            COUNT: begin
                if (counter == TIMEOUT-1) begin
                    timeout <= 1;
                    state <= TIMEOUT_STATE;
                end else begin
                    counter <= counter + 1;
                    state <= COUNT;
                end
            end
            TIMEOUT_STATE: begin
                if (data_valid) begin
                    parity <= ^data;
                    counter <= 0;
                    timeout <= 0;
                    state <= IDLE;
                end else begin
                    state <= TIMEOUT_STATE;
                end
            end
            default: state <= IDLE;
        endcase
    end
end
endmodule