//SystemVerilog
//IEEE 1364-2005 Verilog
module ReloadTimer #(
    parameter DW = 8
) (
    input wire clk,
    input wire rst_n,
    input wire [DW-1:0] reload_val,
    output wire timeout
);
    // Counter and control signals
    reg [DW-1:0] cnt;
    wire timeout_condition;
    
    // Timeout detection - optimized to use combinational logic
    assign timeout_condition = (cnt == 'd1);
    
    // Registered timeout signal to maintain timing
    reg timeout_reg;
    assign timeout = timeout_reg;
    
    // Combined counter and timeout logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cnt <= reload_val;
            timeout_reg <= 1'b0;
        end else begin
            if (timeout_condition) begin
                cnt <= reload_val;
                timeout_reg <= 1'b1;
            end else begin
                cnt <= cnt - 1'b1;
                timeout_reg <= 1'b0;
            end
        end
    end
    
endmodule