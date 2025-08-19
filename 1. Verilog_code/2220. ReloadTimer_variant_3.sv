//SystemVerilog
module ReloadTimer #(parameter DW=8) (
    input clk, rst_n,
    input [DW-1:0] reload_val,
    output reg timeout
);
    reg [DW-1:0] cnt;
    reg [DW-1:0] reload_val_reg;
    wire reload;
    
    // Register the input before using it in the logic path
    always @(posedge clk) begin
        reload_val_reg <= reload_val;
    end
    
    // Pre-compute reload signal
    assign reload = timeout || !rst_n;
    
    // Move registers past combinational logic
    always @(posedge clk) begin
        if (reload)
            cnt <= reload_val_reg;
        else
            cnt <= cnt - 1;
            
        timeout <= (cnt == 1);
    end
endmodule