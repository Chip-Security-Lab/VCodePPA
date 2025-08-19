//SystemVerilog
module three_level_rom_pipelined (
    input clk,
    input rst_n,
    input [3:0] addr,
    output reg [7:0] data
);

    // 流水线寄存器
    reg [3:0] addr_stage1;
    reg [3:0] addr_stage2;
    reg [7:0] rom_data_stage1;
    reg [7:0] cache_data_stage2;
    
    // 存储单元
    reg [7:0] cache [0:3]; // 小型缓存
    reg [7:0] rom [0:15];  // 真实ROM存储
    
    // 控制信号
    reg valid_stage1;
    reg valid_stage2;
    
    // ROM初始化
    initial begin
        rom[0] = 8'h77; 
        rom[1] = 8'h88;
    end
    
    // 第一级流水线：地址寄存
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            addr_stage1 <= 4'b0;
            valid_stage1 <= 1'b0;
        end else begin
            addr_stage1 <= addr;
            valid_stage1 <= 1'b1;
        end
    end

    // 第一级流水线：ROM数据读取
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rom_data_stage1 <= 8'b0;
        end else begin
            rom_data_stage1 <= rom[addr];
        end
    end
    
    // 第二级流水线：地址传递
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            addr_stage2 <= 4'b0;
            valid_stage2 <= 1'b0;
        end else begin
            addr_stage2 <= addr_stage1;
            valid_stage2 <= valid_stage1;
        end
    end

    // 第二级流水线：缓存更新
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cache_data_stage2 <= 8'b0;
        end else begin
            cache[addr_stage1[1:0]] <= rom_data_stage1;
            cache_data_stage2 <= cache[addr_stage1[1:0]];
        end
    end
    
    // 第三级流水线：数据输出
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data <= 8'b0;
        end else if (valid_stage2) begin
            data <= cache_data_stage2;
        end
    end

endmodule