module watchdog_rst_sync (
    input  wire clk,
    input  wire ext_rst_n,
    input  wire watchdog_trigger,
    output reg  combined_rst_n
);
    reg [1:0] ext_rst_sync;
    reg       watchdog_rst_n;
    
    always @(posedge clk or negedge ext_rst_n) begin
        if (!ext_rst_n)
            ext_rst_sync <= 2'b00;
        else
            ext_rst_sync <= {ext_rst_sync[0], 1'b1};
    end
    
    always @(posedge clk) begin
        if (watchdog_trigger)
            watchdog_rst_n <= 1'b0;
        else
            watchdog_rst_n <= 1'b1;
    end
    
    always @(posedge clk)
        combined_rst_n <= ext_rst_sync[1] & watchdog_rst_n;
endmodule
