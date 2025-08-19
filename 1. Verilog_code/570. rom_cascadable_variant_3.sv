//SystemVerilog
module rom_cascadable #(parameter STAGES=3)(
    input wire clk,                      // 添加时钟输入用于流水线寄存器
    input wire rst_n,                    // 添加复位信号
    input wire [7:0] addr,               // 地址输入
    output wire [23:0] data              // 数据输出
);
    // 声明主数据通路的阶段信号
    logic [7:0] addr_pipeline [0:STAGES]; // 地址流水线
    logic [7:0] data_stages [0:STAGES];   // 数据流水线
    
    // 第一级地址寄存器
    always_ff @(posedge clk or negedge rst_n) begin
        if (~rst_n)
            addr_pipeline[0] <= 8'h0;
        else
            addr_pipeline[0] <= addr;
    end
    
    // 生成流水线级联结构
    genvar i;
    generate
        for(i=0; i<STAGES; i=i+1) begin : pipeline_stage
            // 实例化ROM模块，使用流水线化的地址
            rom_async_opt #(
                .AW(8),
                .DW(8)
            ) u_rom (
                .clk(clk),
                .a(addr_pipeline[i]),
                .dout(data_stages[i+1])
            );
            
            // 除了最后一个阶段，其他阶段都需要传递地址到下一级
            if (i < STAGES-1) begin : addr_reg
                always_ff @(posedge clk or negedge rst_n) begin
                    if (~rst_n)
                        addr_pipeline[i+1] <= 8'h0;
                    else
                        addr_pipeline[i+1] <= addr_pipeline[i];
                end
            end
        end
    endgenerate
    
    // 输出数据拼接 - 使用已寄存的数据
    assign data = {data_stages[1], data_stages[2], data_stages[3]};
endmodule

// 优化的异步ROM模块，加入流水线寄存器改善时序
module rom_async_opt #(parameter AW=8, parameter DW=8)(
    input wire clk,                      // 添加时钟输入用于输出寄存
    input wire [AW-1:0] a,               // 地址输入
    output logic [DW-1:0] dout           // 数据输出
);
    // 内部信号声明
    logic [DW-1:0] mem_data;             // 存储器输出数据
    
    // 使用块RAM推断模式，设置适当的属性
    (* ram_style = "block" *) logic [DW-1:0] mem [0:(1<<AW)-1];
    
    // 初始化存储器内容
    initial begin
        for (int i = 0; i < (1<<AW); i++)
            mem[i] = i & {DW{1'b1}};
    end
    
    // 内存读取逻辑
    always_comb begin
        mem_data = mem[a];
    end
    
    // 寄存器化输出以改善时序
    always_ff @(posedge clk) begin
        dout <= mem_data;
    end
endmodule