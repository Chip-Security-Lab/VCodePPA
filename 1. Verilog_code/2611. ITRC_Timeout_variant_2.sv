//SystemVerilog
module ITRC_Timeout #(
    parameter TIMEOUT_CYCLES = 100
)(
    input clk,
    input rst_n,
    input int_req,
    input int_ack,
    output reg timeout
);
    reg [$clog2(TIMEOUT_CYCLES):0] counter;
    reg [$clog2(TIMEOUT_CYCLES):0] counter_next;
    reg timeout_next;
    reg int_req_dly;
    reg int_ack_dly;
    
    always @(posedge clk) begin
        if (!rst_n) begin
            counter <= 0;
            timeout <= 0;
            int_req_dly <= 0;
            int_ack_dly <= 0;
        end else begin
            int_req_dly <= int_req;
            int_ack_dly <= int_ack;
            counter <= counter_next;
            timeout <= timeout_next;
        end
    end
    
    always @(*) begin
        if (int_req_dly && !int_ack_dly && counter >= TIMEOUT_CYCLES) begin
            timeout_next = 1;
            counter_next = counter;
        end else if (int_req_dly && !int_ack_dly) begin
            counter_next = counter + 1;
            timeout_next = 0;
        end else begin
            counter_next = 0;
            timeout_next = 0;
        end
    end
endmodule