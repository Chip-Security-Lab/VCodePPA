//SystemVerilog
module true_dual_port_ram #(
    parameter DW = 16,  // 数据宽度
    parameter AW = 8    // 地址宽度
)(
    // 端口A接口
    input                  clk_a,
    input      [AW-1:0]    addr_a,
    input                  wr_a,
    input      [DW-1:0]    din_a,
    output reg [DW-1:0]    dout_a,
    
    // 端口B接口
    input                  clk_b,
    input      [AW-1:0]    addr_b,
    input                  wr_b,
    input      [DW-1:0]    din_b,
    output reg [DW-1:0]    dout_b
);

    // 存储器定义
    reg [DW-1:0] mem [(1<<AW)-1:0];
    
    // 端口A流水线寄存器
    reg [AW-1:0] addr_a_stage1;
    reg [AW-1:0] addr_a_stage2;
    reg          wr_a_stage1;
    reg          wr_a_stage2;
    reg [DW-1:0] din_a_stage1;
    reg [DW-1:0] din_a_stage2;
    reg [DW-1:0] mem_data_a_stage3;
    reg [DW-1:0] mem_data_a_stage4;
    
    // 端口B流水线寄存器
    reg [AW-1:0] addr_b_stage1;
    reg [AW-1:0] addr_b_stage2;
    reg          wr_b_stage1;
    reg          wr_b_stage2;
    reg [DW-1:0] din_b_stage1;
    reg [DW-1:0] din_b_stage2;
    reg [DW-1:0] mem_data_b_stage3;
    reg [DW-1:0] mem_data_b_stage4;
    
    // 端口A数据流水线 - 增加到5级流水线
    always @(posedge clk_a) begin
        // 第一级：输入信号寄存
        addr_a_stage1 <= addr_a;
        wr_a_stage1 <= wr_a;
        din_a_stage1 <= din_a;
        
        // 第二级：传递控制信号和数据
        addr_a_stage2 <= addr_a_stage1;
        wr_a_stage2 <= wr_a_stage1;
        din_a_stage2 <= din_a_stage1;
        
        // 第三级：存储器访问
        if (wr_a_stage2) begin
            mem[addr_a_stage2] <= din_a_stage2;
        end
        mem_data_a_stage3 <= mem[addr_a_stage2];
        
        // 第四级：数据处理中间阶段
        mem_data_a_stage4 <= mem_data_a_stage3;
        
        // 第五级：输出寄存
        dout_a <= mem_data_a_stage4;
    end
    
    // 端口B数据流水线 - 增加到5级流水线
    always @(posedge clk_b) begin
        // 第一级：输入信号寄存
        addr_b_stage1 <= addr_b;
        wr_b_stage1 <= wr_b;
        din_b_stage1 <= din_b;
        
        // 第二级：传递控制信号和数据
        addr_b_stage2 <= addr_b_stage1;
        wr_b_stage2 <= wr_b_stage1;
        din_b_stage2 <= din_b_stage1;
        
        // 第三级：存储器访问
        if (wr_b_stage2) begin
            mem[addr_b_stage2] <= din_b_stage2;
        end
        mem_data_b_stage3 <= mem[addr_b_stage2];
        
        // 第四级：数据处理中间阶段
        mem_data_b_stage4 <= mem_data_b_stage3;
        
        // 第五级：输出寄存
        dout_b <= mem_data_b_stage4;
    end

endmodule