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

    // Counter logic
    always @(posedge clk) begin
        if (rst) begin
            counter <= 0;
        end else if (data_valid) begin
            counter <= 0;
        end else if (counter < TIMEOUT-1) begin
            counter <= counter + 1;
        end
    end

    // Parity calculation
    always @(posedge clk) begin
        if (rst) begin
            parity <= 0;
        end else if (data_valid) begin
            parity <= ^data;
        end
    end

    // Timeout detection
    always @(posedge clk) begin
        if (rst) begin
            timeout <= 0;
        end else if (data_valid) begin
            timeout <= 0;
        end else if (counter == TIMEOUT-1) begin
            timeout <= 1;
        end
    end
endmodule