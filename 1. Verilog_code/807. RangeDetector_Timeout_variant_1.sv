//SystemVerilog
module RangeDetector_Timeout #(
    parameter WIDTH = 8,
    parameter TIMEOUT = 10
)(
    input clk, rst_n,
    input [WIDTH-1:0] data_in,
    input [WIDTH-1:0] threshold,
    output timeout
);
    // Internal signals
    wire threshold_exceeded;
    wire [$clog2(TIMEOUT):0] count_value;
    wire timeout_detected;
    
    // Instantiate comparator submodule
    ThresholdComparator #(
        .WIDTH(WIDTH)
    ) comparator_inst (
        .data_in(data_in),
        .threshold(threshold),
        .threshold_exceeded(threshold_exceeded)
    );
    
    // Instantiate counter submodule
    TimeoutCounter #(
        .TIMEOUT(TIMEOUT)
    ) counter_inst (
        .clk(clk),
        .rst_n(rst_n),
        .enable(threshold_exceeded),
        .count_value(count_value),
        .timeout_detected(timeout_detected)
    );
    
    // Instantiate timeout detector submodule
    TimeoutDetector timeout_detector_inst (
        .clk(clk),
        .rst_n(rst_n),
        .timeout_detected(timeout_detected),
        .timeout(timeout)
    );
    
endmodule

module ThresholdComparator #(
    parameter WIDTH = 8
)(
    input [WIDTH-1:0] data_in,
    input [WIDTH-1:0] threshold,
    output threshold_exceeded
);
    // Combinational logic for comparison
    assign threshold_exceeded = (data_in > threshold);
    
endmodule

module TimeoutCounter #(
    parameter TIMEOUT = 10
)(
    input clk,
    input rst_n,
    input enable,
    output [$clog2(TIMEOUT):0] count_value,
    output timeout_detected
);
    // Counter register
    reg [$clog2(TIMEOUT):0] counter;
    
    // Assign output signals
    assign count_value = counter;
    assign timeout_detected = (counter == TIMEOUT);
    
    // Counter logic
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            counter <= 0;
        end
        else begin
            if(enable) begin
                counter <= (counter < TIMEOUT) ? counter + 1 : TIMEOUT;
            end
            else begin
                counter <= 0;
            end
        end
    end
    
endmodule

module TimeoutDetector (
    input clk,
    input rst_n,
    input timeout_detected,
    output reg timeout
);
    // Register timeout signal
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            timeout <= 0;
        end
        else begin
            timeout <= timeout_detected;
        end
    end
    
endmodule