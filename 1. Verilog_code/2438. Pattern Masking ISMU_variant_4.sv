//SystemVerilog
module pattern_mask_ismu(
    input clk, reset,
    input req,                   // 请求信号（替代valid）
    input [7:0] interrupt,
    input [7:0] mask_pattern,
    input [2:0] pattern_sel,
    output reg ack,             // 应答信号（替代ready）
    output reg [7:0] masked_interrupt
);
    reg [7:0] mask_enable;
    reg data_received;
    reg processing_done;
    
    // 掩码逻辑
    always @(*) begin
        case (pattern_sel)
            3'd0: mask_enable = 8'hFF;         // No masking (pass all)
            3'd1: mask_enable = 8'h00;         // Mask all (block all)
            3'd2: mask_enable = 8'hF0;         // Pass upper half
            3'd3: mask_enable = 8'h0F;         // Pass lower half
            3'd4: mask_enable = 8'h55;         // Pass alternating
            3'd5: mask_enable = 8'hAA;         // Pass alternating
            3'd6: mask_enable = ~mask_pattern; // Custom pattern (inverted)
            default: mask_enable = 8'hFF;      // Default: pass all
        endcase
    end
    
    // 请求-应答握手状态控制
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            data_received <= 1'b0;
            ack <= 1'b0;
            processing_done <= 1'b0;
        end
        else begin
            // 当接收到请求且尚未确认时，设置数据接收标志
            if (req && !data_received && !ack) begin
                data_received <= 1'b1;
                ack <= 1'b1;  // 确认接收
            end
            // 完成处理后重置
            else if (ack && data_received) begin
                processing_done <= 1'b1;
            end
            // 当请求撤销时，复位状态
            else if (!req && processing_done) begin
                data_received <= 1'b0;
                ack <= 1'b0;
                processing_done <= 1'b0;
            end
        end
    end
    
    // 数据处理逻辑
    always @(posedge clk or posedge reset) begin
        if (reset)
            masked_interrupt <= 8'h00;
        else if (data_received && !processing_done)
            masked_interrupt <= interrupt & mask_enable;
    end
endmodule