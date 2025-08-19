//SystemVerilog
module Timer_AsyncComb (
    input clk, rst,
    input [4:0] delay,
    output reg timeout
);
    reg [4:0] cnt;
    reg [4:0] delay_reg;
    reg compare_result;
    
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            delay_reg <= 0;
        end else begin
            delay_reg <= delay;
        end
    end
    
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            cnt <= 0;
        end else begin
            cnt <= cnt + 1;
        end
    end
    
    always @(*) begin
        compare_result = (cnt == delay_reg);
    end
    
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            timeout <= 0;
        end else begin
            timeout <= compare_result;
        end
    end
endmodule