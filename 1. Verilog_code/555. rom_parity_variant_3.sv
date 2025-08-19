//SystemVerilog
module rom_parity #(parameter BITS=12)(
    input wire clk,           // 添加时钟信号用于流水线
    input wire rst_n,         // 添加复位信号
    input wire [7:0] addr,
    input wire read_en,       // 添加读使能信号
    output reg [BITS-1:0] data
);
    // 数据流阶段定义
    reg [7:0] addr_stage1;
    reg read_en_stage1;
    reg [BITS-2:0] data_raw_stage1;
    reg [BITS-2:0] data_raw_stage2;
    reg parity_bit_stage2;
    
    // ROM存储单元
    (* ram_style = "block" *) reg [BITS-2:0] mem [0:255];
    
    // ROM初始化
    initial begin
        // 示例值初始化
        mem[0] = 11'b10101010101;
        mem[1] = 11'b01010101010;
        // 其他地址可以在仿真中通过文件加载
        // $readmemb("parity_data.bin", mem);
    end
    
    // 第一级流水线：地址寄存和ROM读取
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            addr_stage1 <= 8'b0;
            read_en_stage1 <= 1'b0;
            data_raw_stage1 <= {(BITS-1){1'b0}};
        end else begin
            addr_stage1 <= addr;
            read_en_stage1 <= read_en;
            if (read_en) begin
                data_raw_stage1 <= mem[addr];
            end
        end
    end
    
    // 第二级流水线：奇偶校验计算
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_raw_stage2 <= {(BITS-1){1'b0}};
            parity_bit_stage2 <= 1'b0;
        end else if (read_en_stage1) begin
            data_raw_stage2 <= data_raw_stage1;
            parity_bit_stage2 <= ^data_raw_stage1; // 计算奇偶校验位
        end
    end
    
    // 第三级流水线：输出组装
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data <= {BITS{1'b0}};
        end else begin
            data <= {parity_bit_stage2, data_raw_stage2};
        end
    end
endmodule