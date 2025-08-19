//SystemVerilog
module serialize_reg(
    input clk, reset,
    input [7:0] parallel_in,
    input load, shift_out,
    output reg [7:0] p_out,
    output serial_out,
    // 请求-应答握手信号
    input req_in,                // 替代valid_in
    output reg ack_out,          // 替代ready_out
    input ack_in,                // 替代ready_in
    output reg req_out           // 替代valid_out
);
    // 增加流水线级数，将原来的2级扩展为4级
    reg [7:0] stage1_data, stage2_data, stage3_data, stage4_data;
    reg stage1_req, stage2_req, stage3_req, stage4_req;
    reg stage1_load, stage2_load, stage3_load, stage4_load;
    reg stage1_shift, stage2_shift, stage3_shift, stage4_shift;
    
    // 流水线阶段1：输入缓冲
    always @(posedge clk) begin
        if (reset) begin
            stage1_data <= 8'b0;
            stage1_req <= 1'b0;
            stage1_load <= 1'b0;
            stage1_shift <= 1'b0;
            ack_out <= 1'b0;
        end else if (!stage1_req && req_in) begin
            stage1_data <= parallel_in;
            stage1_req <= 1'b1;
            stage1_load <= load;
            stage1_shift <= shift_out;
            ack_out <= 1'b1;
        end else if (stage1_req && ack_in) begin
            stage1_req <= 1'b0;
            ack_out <= 1'b0;
        end else begin
            ack_out <= req_in && !stage1_req;
        end
    end
    
    // 流水线阶段2：数据预处理
    always @(posedge clk) begin
        if (reset) begin
            stage2_data <= 8'b0;
            stage2_req <= 1'b0;
            stage2_load <= 1'b0;
            stage2_shift <= 1'b0;
        end else if (!stage2_req && stage1_req) begin
            stage2_data <= stage1_data;
            stage2_req <= 1'b1;
            stage2_load <= stage1_load;
            stage2_shift <= stage1_shift;
        end else if (stage2_req && stage3_req == 1'b0) begin
            stage2_req <= 1'b0;
        end
    end
    
    // 流水线阶段3：操作解码
    always @(posedge clk) begin
        if (reset) begin
            stage3_data <= 8'b0;
            stage3_req <= 1'b0;
            stage3_load <= 1'b0;
            stage3_shift <= 1'b0;
        end else if (!stage3_req && stage2_req) begin
            stage3_data <= stage2_data;
            stage3_req <= 1'b1;
            stage3_load <= stage2_load;
            stage3_shift <= stage2_shift;
        end else if (stage3_req && stage4_req == 1'b0) begin
            stage3_req <= 1'b0;
        end
    end
    
    // 流水线阶段4：数据处理
    always @(posedge clk) begin
        if (reset) begin
            stage4_data <= 8'b0;
            stage4_req <= 1'b0;
            stage4_load <= 1'b0;
            stage4_shift <= 1'b0;
        end else if (!stage4_req && stage3_req) begin
            stage4_data <= stage3_data;
            stage4_req <= 1'b1;
            stage4_load <= stage3_load;
            stage4_shift <= stage3_shift;
        end else if (stage4_req && !req_out) begin
            stage4_req <= 1'b0;
        end
    end
    
    // 输出阶段：执行实际操作
    always @(posedge clk) begin
        if (reset) begin
            p_out <= 8'b0;
            req_out <= 1'b0;
        end else if (!req_out && stage4_req) begin
            if (stage4_load)
                p_out <= stage4_data;
            else if (stage4_shift)
                p_out <= {p_out[6:0], 1'b0};
            
            req_out <= 1'b1;
        end else if (req_out && ack_in) begin
            req_out <= 1'b0;
        end
    end
    
    // 串行输出仍然是MSB优先
    assign serial_out = p_out[7];
    
endmodule