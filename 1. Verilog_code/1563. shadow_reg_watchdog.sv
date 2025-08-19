module shadow_reg_watchdog #(parameter DW=8, TIMEOUT=100) (
    input clk, rst,
    input [DW-1:0] new_data,
    output reg [DW-1:0] safe_data
);
    reg [15:0] counter;
    reg [DW-1:0] pending_data;
    
    always @(posedge clk) begin
        if(rst) begin
            counter <= 0;
            safe_data <= 0;
        end else begin
            counter <= (counter >= TIMEOUT-1) ? 0 : counter + 1;
            if(counter == 0) safe_data <= pending_data;
            pending_data <= new_data;
        end
    end
endmodule