//SystemVerilog
module sw_interrupt_ismu(
    input wire clock, 
    input wire reset_n,
    input wire [3:0] hw_int,
    input wire [3:0] sw_int_set,
    input wire [3:0] sw_int_clr,
    output reg [3:0] combined_int
);
    reg [3:0] sw_int;
    wire [3:0] next_sw_int;
    
    // 重定时优化：移动寄存器位置，将组合逻辑计算提前
    assign next_sw_int = (sw_int | sw_int_set) & ~sw_int_clr;
    
    // 时序逻辑更新状态
    always @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            sw_int <= 4'h0;
            combined_int <= 4'h0;
        end else begin
            sw_int <= next_sw_int;
            // 将组合计算移到时序块中，减少关键路径上的组合逻辑延迟
            combined_int <= hw_int | next_sw_int;
        end
    end
endmodule