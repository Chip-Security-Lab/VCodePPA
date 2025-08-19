//SystemVerilog
module counter_shift_load #(parameter WIDTH=8) (
    input clk, load, shift,
    input [WIDTH-1:0] data,
    output reg [WIDTH-1:0] cnt
);
    reg [WIDTH-1:0] next_cnt;
    
    always @(*) begin
        // 使用补码加法实现减法: next_cnt = cnt + (~1 + 1) = cnt - 1
        // ~1 = 'hFE (对于8位), ~1 + 1 = 'hFF
        next_cnt = cnt + {WIDTH{1'b1}};
    end
    
    always @(posedge clk) begin
        if (load) 
            cnt <= data;
        else if (shift) 
            cnt <= {cnt[WIDTH-2:0], cnt[WIDTH-1]};
        else 
            cnt <= next_cnt;
    end
endmodule