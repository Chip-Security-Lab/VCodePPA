//SystemVerilog
module Timer_SyncLoad #(parameter WIDTH=8) (
    input clk, rst_n, enable,
    input [WIDTH-1:0] preset,
    output reg timeout
);
    reg [WIDTH-1:0] cnt;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cnt <= {WIDTH{1'b0}};
            timeout <= 1'b0;
        end
        else if (enable) begin
            // 直接比较cnt与preset，避免不必要的减法运算
            if (cnt == preset) begin
                cnt <= {WIDTH{1'b0}};
                timeout <= 1'b1;
            end
            else begin
                cnt <= cnt + 1'b1;
                timeout <= 1'b0;
            end
        end
    end
endmodule