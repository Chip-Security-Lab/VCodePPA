//SystemVerilog
module tc_counter #(parameter WIDTH = 8) (
    input wire clock, clear, enable,
    output reg [WIDTH-1:0] counter,
    output wire tc
);
    // 为高扇出信号counter添加缓冲寄存器
    reg [WIDTH-1:0] counter_buf1, counter_buf2;
    
    // 计算末状态信号，使用缓冲的counter值
    assign tc = &counter_buf1 & enable;
    
    always @(posedge clock) begin
        case ({clear, enable})
            2'b10, 2'b11: counter <= {WIDTH{1'b0}};    // clear优先
            2'b01:        counter <= counter + 1'b1;   // enable有效且不清零
            2'b00:        counter <= counter;          // 保持不变
        endcase
        
        // 缓冲寄存器，分散counter的负载
        counter_buf1 <= counter;
        counter_buf2 <= counter;
    end
endmodule