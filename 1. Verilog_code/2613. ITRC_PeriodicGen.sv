module ITRC_PeriodicGen #(
    parameter PERIOD = 100
)(
    input clk,
    input rst_n,
    input en,
    output reg int_out
);
    reg [$clog2(PERIOD):0] counter;
    
    always @(posedge clk) begin
        if (!rst_n) begin
            counter <= 0;
            int_out <= 0;
        end else if (en) begin
            if (counter == PERIOD-1) begin
                int_out <= 1;
                counter <= 0;
            end else begin
                int_out <= 0;
                counter <= counter + 1;
            end
        end
    end
endmodule