//SystemVerilog
module cascade_timer (
    input wire clk, reset, enable, cascade_in,
    output wire cascade_out,
    output wire [15:0] count_val
);
    reg [15:0] counter;
    wire cascade_in_d;
    wire tick;
    
    // 移除了输入端的寄存器，改为组合逻辑后的寄存
    reg cascade_in_sampled, cascade_in_prev;
    
    always @(posedge clk) begin
        cascade_in_sampled <= cascade_in;
        cascade_in_prev <= cascade_in_sampled;
    end
    
    // 检测上升沿重新实现
    assign cascade_in_d = cascade_in_sampled;
    assign tick = cascade_in_sampled & ~cascade_in_prev;
    
    // 将if-else级联结构转换为case语句
    always @(posedge clk) begin
        case ({reset, enable, tick})
            3'b100, 3'b101: counter <= 16'h0000;  // reset=1, 其他任意值
            3'b011:         counter <= counter + 16'h0001;  // reset=0, enable=1, tick=1
            default:        counter <= counter;  // 其他所有情况
        endcase
    end
    
    assign cascade_out = (counter == 16'hFFFF) && tick;
    assign count_val = counter;
endmodule