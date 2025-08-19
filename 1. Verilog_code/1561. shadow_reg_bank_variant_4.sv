//SystemVerilog
module shadow_reg_bank #(parameter DW=8, AW=4) (
    input clk, we,
    input [AW-1:0] addr,
    input [DW-1:0] wdata,
    output [DW-1:0] rdata
);
    // 使用分布式RAM代替寄存器数组以优化资源使用
    (* ram_style = "distributed" *) reg [DW-1:0] shadow_mem [2**AW-1:0];
    
    // 添加读地址寄存器，减少时序关键路径
    reg [AW-1:0] raddr_reg;
    reg [DW-1:0] output_reg;
    reg we_reg;
    reg [DW-1:0] wdata_reg;
    
    // 保存写入地址用于读写冲突检测
    always @(posedge clk) begin
        raddr_reg <= addr;
        we_reg <= we;
        wdata_reg <= wdata;
        
        // 写入逻辑
        if(we) shadow_mem[addr] <= wdata;
        
        // 读取逻辑，带有读写冲突处理
        if(we_reg && (raddr_reg == addr))
            output_reg <= wdata_reg; // 读写冲突，直接使用写入的数据
        else
            output_reg <= shadow_mem[raddr_reg];
    end
    
    assign rdata = output_reg;
endmodule