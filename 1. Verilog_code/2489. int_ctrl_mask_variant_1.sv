//SystemVerilog
//IEEE 1364-2005 Verilog
module int_ctrl_mask #(
    parameter DW = 16
)(
    input wire clk,
    input wire en,
    input wire [DW-1:0] req_in,
    input wire [DW-1:0] mask,
    output reg [DW-1:0] masked_req
);
    // 使用按位与非操作直接实现掩码功能
    // 这种实现方式能够更好地映射到FPGA/ASIC硬件资源
    wire [DW-1:0] masked_result;
    
    // 预计算掩码结果以减少关键路径延迟
    assign masked_result = req_in & (~mask);
    
    // 同步寄存器更新
    always @(posedge clk) begin
        if(en) begin
            masked_req <= masked_result;
        end
    end
endmodule