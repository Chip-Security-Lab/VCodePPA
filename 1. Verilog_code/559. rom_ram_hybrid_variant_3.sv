//SystemVerilog
module rom_ram_hybrid_pipeline #(parameter MODE=0)(
    input clk,
    input [7:0] addr,
    input [15:0] din,
    input rst,
    output reg [15:0] dout,
    
    // 新增流水线控制信号
    input enable,
    output reg ready,
    output reg valid
);
    // 内存数组
    reg [15:0] mem [0:255];
    
    // 流水线寄存器
    reg [7:0] addr_stage1, addr_stage2;
    reg [15:0] dout_stage1, dout_stage2, dout_stage3;
    reg valid_stage1, valid_stage2, valid_stage3;
    
    // 流水线控制寄存器
    reg pipeline_stall;
    reg [1:0] pipeline_count;
    
    // 初始化内存
    integer i;
    initial begin
        for (i = 0; i < 256; i = i + 1)
            mem[i] = 16'h0000;
        pipeline_stall = 1'b0;
        pipeline_count = 2'b00;
        ready = 1'b1;
    end
    
    // 第一级流水线：地址寄存和读取
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            addr_stage1 <= 8'h00;
            valid_stage1 <= 1'b0;
            pipeline_count <= 2'b00;
            ready <= 1'b1;
            pipeline_stall <= 1'b0;
        end else if (enable && !pipeline_stall) begin
            addr_stage1 <= addr;
            valid_stage1 <= 1'b1;
            // 流水线计数与控制
            if (pipeline_count < 2'b11)
                pipeline_count <= pipeline_count + 1'b1;
            // 设置ready状态
            ready <= (pipeline_count < 2'b10);
        end else begin
            valid_stage1 <= 1'b0;
        end
    end
    
    // 第二级流水线：内存访问
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            addr_stage2 <= 8'h00;
            dout_stage1 <= 16'h0000;
            valid_stage2 <= 1'b0;
        end else begin
            addr_stage2 <= addr_stage1;
            dout_stage1 <= mem[addr_stage1];
            valid_stage2 <= valid_stage1;
        end
    end
    
    // 第三级流水线：数据处理
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            dout_stage2 <= 16'h0000;
            valid_stage3 <= 1'b0;
        end else begin
            dout_stage2 <= dout_stage1 + 16'h0001; // 示例操作
            valid_stage3 <= valid_stage2;
        end
    end
    
    // 写入逻辑 - 带有前递检测和处理
    generate
        if(MODE == 1) begin
            reg [7:0] last_write_addr;
            reg last_write_valid;
            reg [15:0] last_write_data;
            
            always @(posedge clk or posedge rst) begin
                if (rst) begin
                    for (i = 0; i < 256; i = i + 1)
                        mem[i] <= 16'h0000;
                    last_write_addr <= 8'h00;
                    last_write_valid <= 1'b0;
                    last_write_data <= 16'h0000;
                end else if (enable && !pipeline_stall) begin
                    mem[addr] <= din;
                    last_write_addr <= addr;
                    last_write_valid <= 1'b1;
                    last_write_data <= din;
                end else begin
                    last_write_valid <= 1'b0;
                end
            end
            
            // 前递逻辑 - 检测流水线中的数据依赖
            always @(*) begin
                pipeline_stall = 1'b0;
                // 检查是否有RAW冒险
                if (last_write_valid && 
                    ((addr_stage1 == last_write_addr) || 
                     (addr_stage2 == last_write_addr))) begin
                    pipeline_stall = 1'b1;
                end
            end
        end else begin
            always @(*) begin
                pipeline_stall = 1'b0;
            end
        end
    endgenerate
    
    // 输出级：最终输出
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            dout <= 16'h0000;
            valid <= 1'b0;
        end else begin
            dout <= dout_stage2;
            valid <= valid_stage3;
        end
    end
    
    // 流水线统计和性能监控逻辑
    reg [31:0] pipeline_throughput_counter;
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            pipeline_throughput_counter <= 32'h0;
        end else if (valid) begin
            pipeline_throughput_counter <= pipeline_throughput_counter + 1;
        end
    end
endmodule