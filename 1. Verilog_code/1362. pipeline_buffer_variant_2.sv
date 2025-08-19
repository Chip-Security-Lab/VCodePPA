//SystemVerilog
module pipeline_buffer (
    input wire clk,
    input wire rst_n,
    input wire [15:0] data_in,
    input wire valid_in,
    output wire ready_out,
    
    output reg [15:0] data_out,
    output reg valid_out,
    input wire ready_in
);
    // 优化后的内部寄存器
    reg [15:0] stage2;
    reg valid2;
    
    // 内部信号
    wire ready_stage2;
    reg ready_stage1;
    
    // 直接处理输入数据，将第一级寄存器向前推移
    wire [15:0] stage1_data = data_in;
    wire stage1_valid = valid_in;
    
    // 握手控制逻辑
    assign ready_stage2 = ready_in || !valid_out;
    assign ready_out = ready_stage1 || !valid2; // 修改ready_out逻辑以适应重定时
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // 异步复位
            stage2 <= 16'h0;
            data_out <= 16'h0;
            valid2 <= 1'b0;
            valid_out <= 1'b0;
            ready_stage1 <= 1'b1;
        end else begin
            // 输出级的握手逻辑
            if (ready_in || !valid_out) begin
                data_out <= stage2;
                valid_out <= valid2;
            end
            
            // 第二级的握手逻辑，现在直接从输入获取数据
            ready_stage1 <= ready_stage2;
            if (ready_stage2) begin
                if (stage1_valid) begin
                    stage2 <= stage1_data;
                    valid2 <= stage1_valid;
                end else begin
                    valid2 <= 1'b0;
                end
            end
        end
    end
endmodule