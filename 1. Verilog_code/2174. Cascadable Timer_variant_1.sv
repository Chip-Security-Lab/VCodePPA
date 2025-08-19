//SystemVerilog
module cascade_timer (
    input wire clk,
    input wire reset,
    input wire enable,
    input wire cascade_in,
    output wire cascade_out,
    output wire [15:0] count_val
);
    reg [15:0] counter;
    reg cascade_in_delayed;
    reg enable_delayed;
    wire tick;
    
    // 直接寄存输入信号，将寄存器移动到输入端
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            cascade_in_delayed <= 1'b0;
            enable_delayed <= 1'b0;
        end
        else begin
            cascade_in_delayed <= cascade_in;
            enable_delayed <= enable;
        end
    end
    
    // 边沿检测组合逻辑移到寄存器之后
    assign tick = cascade_in_delayed & ~(cascade_in_delayed ^ cascade_in);
    
    // 计数器逻辑保持不变
    always @(posedge clk or posedge reset) begin
        if (reset)
            counter <= 16'h0000;
        else if (enable_delayed & tick)
            counter <= counter + 16'h0001;
    end
    
    // 级联输出逻辑优化
    assign cascade_out = tick & (&counter);
    assign count_val = counter;
endmodule