module counter_delay_rst_sync #(
    parameter DELAY_CYCLES = 16
)(
    input  wire clk,
    input  wire raw_rst_n,
    output reg  delayed_rst_n
);
    reg [1:0] sync_stages;
    reg [4:0] delay_counter;
    reg       counting;
    
    always @(posedge clk or negedge raw_rst_n) begin
        if (!raw_rst_n) begin
            sync_stages <= 2'b00;
            delay_counter <= 5'b00000;
            delayed_rst_n <= 1'b0;
            counting <= 1'b0;
        end else begin
            sync_stages <= {sync_stages[0], 1'b1};
            
            if (sync_stages[1] && !counting) begin
                counting <= 1'b1;
                delay_counter <= 5'b00000;
            end else if (counting) begin
                if (delay_counter < DELAY_CYCLES - 1)
                    delay_counter <= delay_counter + 1;
                else
                    delayed_rst_n <= 1'b1;
            end
        end
    end
endmodule