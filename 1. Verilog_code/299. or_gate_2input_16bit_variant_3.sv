//SystemVerilog
module or_gate_2input_16bit (
    input wire clk,         
    input wire rst_n,       
    input wire [15:0] a,    
    input wire [15:0] b,    
    output reg [15:0] y     
);
    // 内部数据流水线寄存器
    reg [7:0] a_lower_r, b_lower_r;
    reg [7:0] a_upper_r, b_upper_r;
    reg [7:0] y_lower_r, y_upper_r;
    
    // 第一级流水线：分段处理低位输入数据
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            a_lower_r <= 8'h0;
            b_lower_r <= 8'h0;
        end else begin
            a_lower_r <= a[7:0];
            b_lower_r <= b[7:0];
        end
    end
    
    // 第一级流水线：分段处理高位输入数据
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            a_upper_r <= 8'h0;
            b_upper_r <= 8'h0;
        end else begin
            a_upper_r <= a[15:8];
            b_upper_r <= b[15:8];
        end
    end
    
    // 第二级流水线：计算低位OR结果
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            y_lower_r <= 8'h0;
        end else begin
            y_lower_r <= a_lower_r | b_lower_r;
        end
    end
    
    // 第二级流水线：计算高位OR结果
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            y_upper_r <= 8'h0;
        end else begin
            y_upper_r <= a_upper_r | b_upper_r;
        end
    end
    
    // 第三级流水线：合并结果到输出寄存器
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            y <= 16'h0;
        end else begin
            y <= {y_upper_r, y_lower_r};
        end
    end

endmodule