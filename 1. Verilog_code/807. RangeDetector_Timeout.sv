module RangeDetector_Timeout #(
    parameter WIDTH = 8,
    parameter TIMEOUT = 10
)(
    input clk, rst_n,
    input [WIDTH-1:0] data_in,
    input [WIDTH-1:0] threshold,
    output reg timeout
);
reg [$clog2(TIMEOUT):0] counter;

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        counter <= 0;
        timeout <= 0;
    end
    else begin
        if(data_in > threshold) begin
            counter <= (counter < TIMEOUT) ? counter + 1 : TIMEOUT;
        end
        else begin
            counter <= 0;
        end
        timeout <= (counter == TIMEOUT);
    end
end
endmodule
