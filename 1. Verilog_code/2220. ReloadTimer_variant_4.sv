//SystemVerilog
/* IEEE 1364-2005 compliant */
module ReloadTimer #(parameter DW=8) (
    input wire clk, rst_n,
    input wire [DW-1:0] reload_val,
    output reg timeout
);
    reg [DW-1:0] cnt;
    wire reload;
    
    // Optimize reload logic
    assign reload = timeout | ~rst_n;
    
    // Counter implementation using case statement
    always @(posedge clk) begin
        case ({reload, |cnt})
            2'b10, 2'b11: cnt <= reload_val;  // Reload condition has priority
            2'b01:        cnt <= cnt - 1'b1;  // Decrement when not zero and not reloading
            2'b00:        cnt <= cnt;         // Hold value when zero and not reloading
        endcase
    end
    
    // Optimize timeout detection
    always @(posedge clk) begin
        timeout <= (cnt == 1'b1);
    end
endmodule