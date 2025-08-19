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

always @(posedge clk) begin
    if (rst) begin
        counter <= 0;
        parity <= 0;
        timeout <= 0;
    end else if (data_valid) begin
        parity <= ^data;
        counter <= 0;
        timeout <= 0;
    end else begin
        if (counter == TIMEOUT-1)
            timeout <= 1;
        else
            counter <= counter + 1;
    end
end
endmodule