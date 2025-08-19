//SystemVerilog
module biphase_mark_codec (
    input wire clk, rst,
    input wire encode, decode,
    input wire data_in,
    input wire biphase_in,
    output reg biphase_out,
    output reg data_out,
    output reg data_valid
);
    reg last_bit;
    reg [1:0] bit_timer;
    reg timer_en;
    reg toggle_at_start;
    reg toggle_at_middle;
    
    // 计时器控制逻辑
    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            bit_timer <= 2'b00;
            timer_en <= 1'b0;
        end else if (encode) begin
            timer_en <= 1'b1;
            bit_timer <= bit_timer + 2'b01;
        end else begin
            timer_en <= 1'b0;
        end
    end
    
    // 编码状态判断逻辑
    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            toggle_at_start <= 1'b0;
            toggle_at_middle <= 1'b0;
        end else if (encode) begin
            toggle_at_start <= (bit_timer == 2'b00);
            toggle_at_middle <= (bit_timer == 2'b10) && data_in;
        end else begin
            toggle_at_start <= 1'b0;
            toggle_at_middle <= 1'b0;
        end
    end
    
    // 输出控制逻辑
    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            biphase_out <= 1'b0;
            last_bit <= 1'b0;
        end else if (encode) begin
            if (toggle_at_start || toggle_at_middle)
                biphase_out <= ~biphase_out;
        end
    end
    
    // 数据有效信号逻辑
    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            data_valid <= 1'b0;
        end else begin
            data_valid <= decode && (bit_timer == 2'b11);
        end
    end
    
    // 解码输出逻辑（保留为空，与原代码一致）
    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            data_out <= 1'b0;
        end else if (decode) begin
            // 解码逻辑将在这里实现
        end
    end
    
endmodule