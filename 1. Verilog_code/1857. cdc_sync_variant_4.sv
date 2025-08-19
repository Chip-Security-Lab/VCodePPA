//SystemVerilog
module cdc_sync #(parameter WIDTH=1) (
    input src_clk, dst_clk, rst,
    input [WIDTH-1:0] async_in,
    output reg [WIDTH-1:0] sync_out
);
    // 直接在源时钟域将输入信号传入，无需额外寄存器
    wire [WIDTH-1:0] src_data;
    assign src_data = async_in;
    
    // 目标时钟域寄存器 - 第一级同步
    reg [WIDTH-1:0] sync_reg1;
    
    // 目标时钟域第一级同步
    always @(posedge dst_clk or posedge rst) begin
        if (rst) 
            sync_reg1 <= {WIDTH{1'b0}};
        else 
            sync_reg1 <= src_data;
    end

    // 目标时钟域第二级同步
    always @(posedge dst_clk or posedge rst) begin
        if (rst) 
            sync_out <= {WIDTH{1'b0}};
        else 
            sync_out <= sync_reg1;
    end
endmodule