//SystemVerilog
module watchdog_rst_sync (
    input  wire clk,
    input  wire ext_rst_n,
    input  wire watchdog_trigger,
    output reg  combined_rst_n
);
    reg [1:0] ext_rst_sync;
    reg       watchdog_rst_n;
    
    always @(posedge clk or negedge ext_rst_n)
        ext_rst_sync <= (!ext_rst_n) ? 2'b00 : {ext_rst_sync[0], 1'b1};
    
    always @(posedge clk)
        watchdog_rst_n <= watchdog_trigger ? 1'b0 : 1'b1;
    
    always @(posedge clk)
        combined_rst_n <= ext_rst_sync[1] & watchdog_rst_n;
endmodule