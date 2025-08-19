//SystemVerilog
module ITRC_Timeout #(
    parameter TIMEOUT_CYCLES = 100
)(
    input clk,
    input rst_n,
    input int_req,
    input int_ack,
    output timeout
);
    wire request_active;
    wire [$clog2(TIMEOUT_CYCLES):0] counter_value;
    wire counter_reset;
    wire timeout_detected;

    ITRC_RequestDetector u_req_detector (
        .clk(clk),
        .rst_n(rst_n),
        .int_req(int_req),
        .int_ack(int_ack),
        .request_active(request_active),
        .counter_reset(counter_reset)
    );

    ITRC_TimeoutCounter #(
        .TIMEOUT_CYCLES(TIMEOUT_CYCLES)
    ) u_counter (
        .clk(clk),
        .rst_n(rst_n),
        .enable(request_active),
        .reset_counter(counter_reset),
        .counter_value(counter_value),
        .timeout_detected(timeout_detected)
    );

    ITRC_TimeoutFlag u_timeout_flag (
        .clk(clk),
        .rst_n(rst_n),
        .timeout_detected(timeout_detected),
        .counter_reset(counter_reset),
        .timeout(timeout)
    );
endmodule

module ITRC_RequestDetector (
    input clk,
    input rst_n,
    input int_req,
    input int_ack,
    output reg request_active,
    output reg counter_reset
);
    wire req_active_next;
    wire counter_reset_next;
    
    assign req_active_next = int_req & ~int_ack;
    assign counter_reset_next = ~req_active_next;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            request_active <= 1'b0;
            counter_reset <= 1'b1;
        end else begin
            request_active <= req_active_next;
            counter_reset <= counter_reset_next;
        end
    end
endmodule

module ITRC_TimeoutCounter #(
    parameter TIMEOUT_CYCLES = 100
)(
    input clk,
    input rst_n,
    input enable,
    input reset_counter,
    output reg [$clog2(TIMEOUT_CYCLES):0] counter_value,
    output reg timeout_detected
);
    wire [$clog2(TIMEOUT_CYCLES):0] counter_next;
    wire timeout_next;
    
    assign counter_next = (reset_counter) ? 0 : 
                         (enable & (counter_value < TIMEOUT_CYCLES)) ? counter_value + 1 : counter_value;
    assign timeout_next = (reset_counter) ? 1'b0 : 
                         (enable & (counter_value >= TIMEOUT_CYCLES)) ? 1'b1 : timeout_detected;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            counter_value <= 0;
            timeout_detected <= 1'b0;
        end else begin
            counter_value <= counter_next;
            timeout_detected <= timeout_next;
        end
    end
endmodule

module ITRC_TimeoutFlag (
    input clk,
    input rst_n,
    input timeout_detected,
    input counter_reset,
    output reg timeout
);
    wire timeout_next;
    
    assign timeout_next = (counter_reset) ? 1'b0 : timeout_detected;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            timeout <= 1'b0;
        end else begin
            timeout <= timeout_next;
        end
    end
endmodule