//SystemVerilog
module int_ctrl_software #(parameter WIDTH=8)(
    input wire clk,
    input wire rst_n,       // 复位信号
    input wire wr_en,
    input wire [WIDTH-1:0] sw_int,
    input wire ready_in,    // 输入就绪信号
    output wire ready_out,  // 输出就绪信号
    output wire valid_out,  // 有效输出标志
    output reg [WIDTH-1:0] int_out
);

    // 扩展为5级流水线的寄存器和控制信号
    reg [WIDTH-1:0] sw_int_stage1;
    reg wr_en_stage1;
    reg valid_stage1;
    
    reg [WIDTH-1:0] sw_int_stage2;
    reg wr_en_stage2;
    reg valid_stage2;
    
    reg [WIDTH-1:0] sw_int_stage3;
    reg wr_en_stage3;
    reg valid_stage3;
    
    reg [WIDTH-1:0] sw_int_stage4;
    reg wr_en_stage4;
    reg valid_stage4;
    
    // 流水线阶段1：输入捕获
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sw_int_stage1 <= {WIDTH{1'b0}};
            wr_en_stage1 <= 1'b0;
            valid_stage1 <= 1'b0;
        end else if (ready_out) begin
            sw_int_stage1 <= sw_int;
            wr_en_stage1 <= wr_en;
            valid_stage1 <= ready_in;
        end
    end
    
    // 流水线阶段2：前处理
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sw_int_stage2 <= {WIDTH{1'b0}};
            wr_en_stage2 <= 1'b0;
            valid_stage2 <= 1'b0;
        end else if (ready_out) begin
            sw_int_stage2 <= sw_int_stage1;
            wr_en_stage2 <= wr_en_stage1;
            valid_stage2 <= valid_stage1;
        end
    end
    
    // 流水线阶段3：中间处理
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sw_int_stage3 <= {WIDTH{1'b0}};
            wr_en_stage3 <= 1'b0;
            valid_stage3 <= 1'b0;
        end else if (ready_out) begin
            sw_int_stage3 <= sw_int_stage2;
            wr_en_stage3 <= wr_en_stage2;
            valid_stage3 <= valid_stage2;
        end
    end
    
    // 流水线阶段4：后处理
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sw_int_stage4 <= {WIDTH{1'b0}};
            wr_en_stage4 <= 1'b0;
            valid_stage4 <= 1'b0;
        end else if (ready_out) begin
            sw_int_stage4 <= sw_int_stage3;
            wr_en_stage4 <= wr_en_stage3;
            valid_stage4 <= valid_stage3;
        end
    end
    
    // 流水线阶段5：产生输出
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            int_out <= {WIDTH{1'b0}};
        end else if (ready_out) begin
            if (wr_en_stage4) 
                int_out <= sw_int_stage4;
            else 
                int_out <= {WIDTH{1'b0}};
        end
    end
    
    // 控制逻辑
    reg valid_out_reg;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            valid_out_reg <= 1'b0;
        end else if (ready_out) begin
            valid_out_reg <= valid_stage4;
        end
    end
    
    assign valid_out = valid_out_reg;
    assign ready_out = 1'b1;  // 简化版本，始终就绪接收数据

endmodule