//SystemVerilog
module pl_reg_array #(parameter DW=8, AW=4) (
    input                 clk,
    input                 rst_n,
    input                 we,
    input                 valid_in,
    output                ready_out,
    input      [AW-1:0]   addr,
    input      [DW-1:0]   data_in,
    output     [DW-1:0]   data_out,
    output                valid_out
);

    // 内存阵列
    reg [DW-1:0] mem [0:(1<<AW)-1];
    
    // 流水线级寄存器 - 第一级
    reg [AW-1:0] addr_stage1;
    reg [DW-1:0] data_in_stage1;
    reg we_stage1;
    reg valid_stage1;
    
    // 流水线级寄存器 - 第二级
    reg [AW-1:0] addr_stage2;
    reg valid_stage2;
    reg [DW-1:0] read_data_stage2;
    
    // 预读取寄存器 - 用于减少关键路径延迟
    reg [DW-1:0] pre_read_data;
    
    // 流水线控制信号
    assign ready_out = 1'b1;
    
    // 第一级流水线 - 接收请求并处理写操作
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            addr_stage1    <= {AW{1'b0}};
            data_in_stage1 <= {DW{1'b0}};
            we_stage1      <= 1'b0;
            valid_stage1   <= 1'b0;
        end 
        else begin
            addr_stage1    <= addr;
            data_in_stage1 <= data_in;
            we_stage1      <= we;
            valid_stage1   <= valid_in;
        end
    end
    
    // 写操作逻辑 - 单独分离以减少关键路径
    always @(posedge clk) begin
        if (we) begin
            mem[addr] <= data_in;
        end
    end
    
    // 预读取逻辑 - 减少第二级的关键路径
    always @(posedge clk) begin
        pre_read_data <= mem[addr_stage1];
    end
    
    // 第二级流水线 - 读取和输出
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            addr_stage2      <= {AW{1'b0}};
            valid_stage2     <= 1'b0;
            read_data_stage2 <= {DW{1'b0}};
        end 
        else begin
            addr_stage2      <= addr_stage1;
            valid_stage2     <= valid_stage1;
            
            // 使用预读取的数据，减少关键路径延迟
            read_data_stage2 <= pre_read_data;
        end
    end
    
    // 输出赋值
    assign data_out = read_data_stage2;
    assign valid_out = valid_stage2;

endmodule