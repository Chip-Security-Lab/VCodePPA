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
    
    always @(posedge clk) begin
        if (!rst_n) begin
            counter <= 0;
            timeout <= 0;
        end else begin
            if (int_req && !int_ack) begin
                if (counter >= TIMEOUT_CYCLES)
                    timeout <= 1;
                else
                    counter <= counter + 1;
            end else begin
                counter <= 0;
                timeout <= 0;
            end
        end
    end
endmodule