//SystemVerilog
module preset_reg(
    input clk, sync_preset, load,
    input [11:0] data_in,
    output reg [11:0] data_out
);
    // 使用参数定义preset值，提高可配置性和可读性
    parameter PRESET_VALUE = 12'hFFF;
    
    // 直接使用输出寄存器，省去中间寄存器
    always @(posedge clk) begin
        if (sync_preset)
            data_out <= PRESET_VALUE;
        else if (load)
            data_out <= data_in;
        // 保持当前值的隐含else分支
    end
endmodule