//SystemVerilog
module pl_reg_array #(parameter DW=8, AW=4) (
    input wire clk,
    input wire rst_n,
    input wire valid_in,
    input wire we,
    input wire [AW-1:0] addr,
    input wire [DW-1:0] data_in,
    output wire [DW-1:0] data_out,
    output wire valid_out,
    output wire ready
);
    // 内存数组
    reg [DW-1:0] mem [0:(1<<AW)-1];
    
    // 流水线寄存器 - 第一级
    reg [AW-1:0] addr_stage1;
    reg [DW-1:0] data_in_stage1;
    reg we_stage1;
    reg valid_stage1;
    
    // 流水线寄存器 - 第二级
    reg [AW-1:0] addr_stage2;
    reg valid_stage2;
    reg [DW-1:0] read_data_stage2;
    
    // 流水线控制
    assign ready = 1'b1; // 本设计总是准备好接收新输入
    assign valid_out = valid_stage2;
    assign data_out = read_data_stage2;
    
    // 第一级流水线 - 寄存请求信号和地址
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            addr_stage1 <= {AW{1'b0}};
            data_in_stage1 <= {DW{1'b0}};
            we_stage1 <= 1'b0;
            valid_stage1 <= 1'b0;
        end else begin
            addr_stage1 <= addr;
            data_in_stage1 <= data_in;
            we_stage1 <= we;
            valid_stage1 <= valid_in;
        end
    end
    
    // 第二级流水线 - 执行内存操作
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            addr_stage2 <= {AW{1'b0}};
            valid_stage2 <= 1'b0;
            read_data_stage2 <= {DW{1'b0}};
        end else begin
            addr_stage2 <= addr_stage1;
            valid_stage2 <= valid_stage1;
            
            // 写优先逻辑 - 如果当前周期是写，且地址匹配，则转发写入数据
            if (we_stage1 && (addr_stage1 == addr_stage2) && valid_stage2) begin
                read_data_stage2 <= data_in_stage1;
            end else begin
                read_data_stage2 <= mem[addr_stage1];
            end
        end
    end
    
    // 内存写入逻辑
    always @(posedge clk) begin
        if (we_stage1 && valid_stage1) begin
            mem[addr_stage1] <= data_in_stage1;
        end
    end
endmodule