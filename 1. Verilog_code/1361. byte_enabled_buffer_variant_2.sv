//SystemVerilog
module byte_enabled_buffer (
    input wire clk,
    input wire rst_n,
    input wire [31:0] data_in,
    input wire [3:0] byte_en,
    input wire write,
    input wire ready_in,
    output wire ready_out,
    output wire valid_out,
    output wire [31:0] data_out
);

    // 内部寄存器信号
    reg [31:0] data_stage1_reg, data_stage2_reg, data_out_reg;
    reg [3:0] byte_en_stage1_reg, byte_en_stage2_reg;
    reg write_stage1_reg, write_stage2_reg;
    reg valid_stage1_reg, valid_stage2_reg, valid_stage3_reg;
    
    // 组合逻辑的中间信号
    wire [31:0] data_stage2_next, data_out_next;
    
    // 流水线控制逻辑 - 组合逻辑部分
    assign ready_out = 1'b1;  // 此设计总是可以接收新数据
    assign valid_out = valid_stage3_reg;
    assign data_out = data_out_reg;
    
    // 第一阶段组合逻辑
    wire valid_stage1_next = ready_in & write;
    
    // 第二阶段组合逻辑 - 处理数据的前两个字节
    assign data_stage2_next = calc_stage2_data(
        data_stage1_reg, 
        byte_en_stage1_reg, 
        write_stage1_reg, 
        valid_stage1_reg
    );
    
    // 第三阶段组合逻辑 - 处理数据的后两个字节
    assign data_out_next = calc_stage3_data(
        data_stage2_reg, 
        byte_en_stage2_reg, 
        write_stage2_reg, 
        valid_stage2_reg
    );
    
    // 时序逻辑部分 - 阶段1寄存器
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_stage1_reg <= 32'b0;
            byte_en_stage1_reg <= 4'b0;
            write_stage1_reg <= 1'b0;
            valid_stage1_reg <= 1'b0;
        end else begin
            if (ready_in) begin
                data_stage1_reg <= data_in;
                byte_en_stage1_reg <= byte_en;
                write_stage1_reg <= write;
                valid_stage1_reg <= valid_stage1_next;
            end
        end
    end
    
    // 时序逻辑部分 - 阶段2寄存器
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_stage2_reg <= 32'b0;
            byte_en_stage2_reg <= 4'b0;
            write_stage2_reg <= 1'b0;
            valid_stage2_reg <= 1'b0;
        end else begin
            data_stage2_reg <= data_stage2_next;
            byte_en_stage2_reg <= byte_en_stage1_reg;
            write_stage2_reg <= write_stage1_reg;
            valid_stage2_reg <= valid_stage1_reg;
        end
    end
    
    // 时序逻辑部分 - 阶段3寄存器
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_out_reg <= 32'b0;
            valid_stage3_reg <= 1'b0;
        end else begin
            data_out_reg <= data_out_next;
            valid_stage3_reg <= valid_stage2_reg;
        end
    end
    
    // 组合逻辑函数 - 阶段2数据计算
    function [31:0] calc_stage2_data;
        input [31:0] data_in;
        input [3:0] byte_en;
        input write;
        input valid;
        
        reg [31:0] result;
    begin
        result = data_in;
        
        if (valid && write) begin
            if (byte_en[0]) result[7:0] = data_in[7:0];
            if (byte_en[1]) result[15:8] = data_in[15:8];
        end
        
        calc_stage2_data = result;
    end
    endfunction
    
    // 组合逻辑函数 - 阶段3数据计算
    function [31:0] calc_stage3_data;
        input [31:0] data_in;
        input [3:0] byte_en;
        input write;
        input valid;
        
        reg [31:0] result;
    begin
        result = data_in;
        
        if (valid && write) begin
            if (byte_en[2]) result[23:16] = data_in[23:16];
            if (byte_en[3]) result[31:24] = data_in[31:24];
        end
        
        calc_stage3_data = result;
    end
    endfunction

endmodule