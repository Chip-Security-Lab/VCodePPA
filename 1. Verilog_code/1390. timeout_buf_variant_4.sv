//SystemVerilog
module timeout_buf #(parameter DW=8, TIMEOUT=100) (
    input clk, rst_n,
    input wr_en, rd_en,
    input [DW-1:0] din,
    output [DW-1:0] dout,
    output valid
);
    reg [DW-1:0] data_reg;
    reg [15:0] timer;
    reg valid_reg;
    
    // 定义状态信号，减少逻辑路径
    wire timer_max = (timer >= TIMEOUT - 1);
    wire clear_valid = rd_en || timer_max;
    wire set_valid = wr_en;
    
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            valid_reg <= 1'b0;
            timer <= 16'b0;
            data_reg <= {DW{1'b0}};
        end else begin
            // 优化控制逻辑，减少嵌套条件
            if(set_valid) begin
                data_reg <= din;
                valid_reg <= 1'b1;
                timer <= 16'b0;
            end else if(valid_reg) begin
                // 使用预计算的比较结果
                if(!timer_max)
                    timer <= timer + 16'b1;
                else
                    valid_reg <= 1'b0;
            end
            
            // 分离读取逻辑，避免多条件竞争
            if(rd_en && valid_reg)
                valid_reg <= 1'b0;
        end
    end
    
    // 连续赋值
    assign dout = data_reg;
    assign valid = valid_reg;
endmodule