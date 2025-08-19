//SystemVerilog
module snapshot_buffer (
    input wire clk,
    input wire [31:0] live_data,
    input wire capture,
    output reg [31:0] snapshot_data
);
    reg capture_reg;
    reg [31:0] live_data_reg;
    
    // 合并的always块 - 将两个posedge clk触发的块合并为一个
    always @(posedge clk) begin
        // 将寄存器向数据源方向拉移
        capture_reg <= capture;
        live_data_reg <= live_data;
        
        // 更新输出寄存器
        if (capture_reg)
            snapshot_data <= live_data_reg;
    end
endmodule