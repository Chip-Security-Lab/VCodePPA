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
    wire timeout_condition;
    wire reset_condition;
    wire counter_full;
    wire counter_inc;
    
    // 提前计算所有条件，减少关键路径延迟
    assign timeout_condition = int_req && !int_ack;
    assign reset_condition = !timeout_condition;
    assign counter_full = (counter >= TIMEOUT_CYCLES);
    assign counter_inc = counter + 1'b1;
    
    always @(posedge clk) begin
        if (!rst_n) begin
            counter <= '0;
            timeout <= 1'b0;
        end else begin
            if (timeout_condition) begin
                timeout <= counter_full;
                counter <= counter_full ? counter : counter_inc;
            end else begin
                counter <= '0;
                timeout <= 1'b0;
            end
        end
    end
endmodule