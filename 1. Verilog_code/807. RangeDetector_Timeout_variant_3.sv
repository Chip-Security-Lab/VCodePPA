//SystemVerilog
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
reg [$clog2(TIMEOUT):0] counter_buf;
reg [$clog2(TIMEOUT):0] counter_buf2;
reg timeout_buf;

// Reset logic
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        counter <= 0;
        counter_buf <= 0;
        counter_buf2 <= 0;
        timeout <= 0;
        timeout_buf <= 0;
    end
end

// Counter update logic
always @(posedge clk) begin
    if(rst_n) begin
        if(data_in > threshold) begin
            counter <= (counter < TIMEOUT) ? counter + 1 : TIMEOUT;
        end
        else begin
            counter <= 0;
        end
    end
end

// Pipeline stage 1
always @(posedge clk) begin
    if(rst_n) begin
        counter_buf <= counter;
    end
end

// Pipeline stage 2
always @(posedge clk) begin
    if(rst_n) begin
        counter_buf2 <= counter_buf;
    end
end

// Timeout detection
always @(posedge clk) begin
    if(rst_n) begin
        timeout_buf <= (counter_buf2 == TIMEOUT);
    end
end

// Output register
always @(posedge clk) begin
    if(rst_n) begin
        timeout <= timeout_buf;
    end
end

endmodule