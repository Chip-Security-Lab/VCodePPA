//SystemVerilog
module hamming_bus_interface(
    input clk, rst, cs, we,
    input [3:0] addr,
    input [7:0] wdata,
    output reg [7:0] rdata,
    output reg ready
);
    // 流水线寄存器
    reg [7:0] wdata_stage1;
    reg [3:0] addr_stage1;
    reg cs_stage1, we_stage1;
    
    // 流水线阶段2寄存器
    reg [7:0] wdata_stage2;
    reg [3:0] addr_stage2;
    reg cs_stage2, we_stage2;
    
    // 编码流水线寄存器
    reg [3:0] data_stage1;
    
    // 最终编码和状态寄存器
    reg [6:0] encoded;
    reg [3:0] status;
    
    // 流水线有效信号
    reg valid_stage1, valid_stage2, valid_stage3;
    
    // 哈明编码查找表 - 索引是4位数据
    reg [6:0] hamming_lut [0:15];
    
    // 初始化哈明编码查找表
    integer i;
    initial begin
        for (i = 0; i < 16; i = i + 1) begin
            // 计算数据位
            hamming_lut[i][2] = i[0];            // 数据位0
            hamming_lut[i][4] = i[1];            // 数据位1
            hamming_lut[i][5] = i[2];            // 数据位2
            hamming_lut[i][6] = i[3];            // 数据位3
            
            // 计算奇偶校验位
            hamming_lut[i][0] = i[0] ^ i[1] ^ i[3];     // 奇偶校验位1
            hamming_lut[i][1] = i[0] ^ i[2] ^ i[3];     // 奇偶校验位2
            hamming_lut[i][3] = i[1] ^ i[2] ^ i[3];     // 奇偶校验位3
        end
    end
    
    // 阶段1: 输入寄存
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            wdata_stage1 <= 8'b0;
            addr_stage1 <= 4'b0;
            cs_stage1 <= 1'b0;
            we_stage1 <= 1'b0;
            valid_stage1 <= 1'b0;
        end else begin
            wdata_stage1 <= wdata;
            addr_stage1 <= addr;
            cs_stage1 <= cs;
            we_stage1 <= we;
            valid_stage1 <= cs;
        end
    end
    
    // 阶段2: 准备查找表索引和输入寄存
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            data_stage1 <= 4'b0;
            wdata_stage2 <= 8'b0;
            addr_stage2 <= 4'b0;
            cs_stage2 <= 1'b0;
            we_stage2 <= 1'b0;
            valid_stage2 <= 1'b0;
        end else begin
            if (cs_stage1 && we_stage1 && addr_stage1 == 4'h0) begin
                data_stage1 <= wdata_stage1[3:0];
            end
            
            wdata_stage2 <= wdata_stage1;
            addr_stage2 <= addr_stage1;
            cs_stage2 <= cs_stage1;
            we_stage2 <= we_stage1;
            valid_stage2 <= valid_stage1;
        end
    end
    
    // 控制和数据路径查找表
    reg [7:0] rdata_lut [0:3];  // 读取数据查找表 - [we|addr]
    
    // 阶段3: 使用查找表并输出
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            encoded <= 7'b0;
            status <= 4'b0;
            rdata <= 8'b0;
            ready <= 1'b0;
            valid_stage3 <= 1'b0;
        end else begin
            valid_stage3 <= valid_stage2;
            
            if (cs_stage2) begin
                // 使用组合逻辑计算rdata_lut索引
                // 索引格式: {we, addr[2]}
                rdata_lut[0] = {1'b0, encoded};    // we=0, addr=0
                rdata_lut[1] = {4'b0, status};     // we=0, addr=4
                rdata_lut[2] = rdata;              // we=1, addr=0 (保持不变)
                rdata_lut[3] = rdata;              // we=1, addr=4 (保持不变)
                
                if (we_stage2) begin
                    // 写操作
                    if (addr_stage2 == 4'h0) begin
                        // 从查找表获取编码
                        encoded <= hamming_lut[data_stage1];
                        status[0] <= 1'b1; // 编码完成
                    end else if (addr_stage2 == 4'h4) begin
                        status <= wdata_stage2[3:0]; // 控制寄存器
                    end
                end else begin
                    // 读操作 - 使用查找表
                    rdata <= rdata_lut[{1'b0, addr_stage2[2]}];
                end
            end
            
            // Ready信号生成
            ready <= valid_stage3 & cs_stage2;
        end
    end
endmodule