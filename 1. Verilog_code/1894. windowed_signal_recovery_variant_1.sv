//SystemVerilog
module windowed_signal_recovery #(
    parameter DATA_WIDTH = 10,
    parameter WINDOW_SIZE = 5
)(
    input wire clk,
    input wire window_enable,
    input wire [DATA_WIDTH-1:0] signal_in,
    output reg [DATA_WIDTH-1:0] signal_out,
    output reg valid
);
    // 寄存器声明
    reg [DATA_WIDTH-1:0] window [0:WINDOW_SIZE-1];
    reg window_enable_delayed;
    reg [DATA_WIDTH-1:0] signal_in_delayed;
    
    // 后向重定时：直接计算各窗口值的和，无需sum_reg中间寄存器
    wire [DATA_WIDTH+3:0] sum_wire;
    wire [DATA_WIDTH-1:0] avg_wire;
    
    // 输入延迟寄存
    always @(posedge clk) begin
        signal_in_delayed <= signal_in;
        window_enable_delayed <= window_enable;
    end
    
    // 窗口移位逻辑
    integer i;
    always @(posedge clk) begin
        if (window_enable_delayed) begin
            // 移位窗口值
            for (i = WINDOW_SIZE-1; i > 0; i = i-1)
                window[i] <= window[i-1];
            window[0] <= signal_in_delayed;
        end
    end
    
    // 组合逻辑：计算窗口内所有值的总和
    assign sum_wire = window[0] + window[1] + window[2] + window[3] + window[4];
    
    // 组合逻辑：计算平均值
    assign avg_wire = sum_wire / WINDOW_SIZE;
    
    // 输出寄存器：后向重定时，将输出寄存器移到组合逻辑之前
    always @(posedge clk) begin
        if (window_enable_delayed) begin
            signal_out <= avg_wire;
            valid <= 1'b1;
        end else begin
            valid <= 1'b0;
        end
    end
    
endmodule