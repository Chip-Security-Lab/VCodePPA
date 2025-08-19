//SystemVerilog
module final_xor_crc16(
    input wire clk,
    input wire reset,
    input wire [7:0] data,
    input wire data_req,      // 替换原来的data_valid
    input wire calc_done_req, // 替换原来的calc_done
    output reg [15:0] crc_out,
    output reg data_ack,      // 新增：数据接收应答信号
    output reg calc_done_ack  // 新增：计算完成应答信号
);
    parameter [15:0] POLY = 16'h1021;
    parameter [15:0] FINAL_XOR = 16'hFFFF;
    
    // 内部握手状态寄存器
    reg data_req_r, calc_done_req_r;
    
    // Stage 1: Input processing and first bit calculation
    reg [15:0] crc_stage1;
    reg [6:0] data_stage1;
    reg req_stage1;
    reg calc_done_stage1;
    
    // Stage 2: Process remaining bits
    reg [15:0] crc_stage2;
    reg [3:0] data_stage2;
    reg req_stage2;
    reg calc_done_stage2;
    
    // Stage 3: Final bits processing
    reg [15:0] crc_stage3;
    reg req_stage3;
    reg calc_done_stage3;
    
    // 握手逻辑
    always @(posedge clk) begin
        if (reset) begin
            data_req_r <= 1'b0;
            calc_done_req_r <= 1'b0;
            data_ack <= 1'b0;
            calc_done_ack <= 1'b0;
        end else begin
            // 边沿检测，只在req信号上升沿时生成应答
            data_req_r <= data_req;
            calc_done_req_r <= calc_done_req;
            
            // 数据请求应答
            if (data_req && !data_req_r) 
                data_ack <= 1'b1;
            else
                data_ack <= 1'b0;
            
            // 计算完成应答
            if (calc_done_req && !calc_done_req_r)
                calc_done_ack <= 1'b1;
            else
                calc_done_ack <= 1'b0;
        end
    end
    
    // Stage 1: Process first bit
    always @(posedge clk) begin
        if (reset) begin
            crc_stage1 <= 16'h0000;
            data_stage1 <= 7'h00;
            req_stage1 <= 1'b0;
            calc_done_stage1 <= 1'b0;
        end else begin
            req_stage1 <= data_req && !data_req_r; // 只在请求上升沿有效
            calc_done_stage1 <= calc_done_req && !calc_done_req_r;
            
            if (data_req && !data_req_r) begin
                // Process first bit
                crc_stage1 <= {crc_out[14:0], 1'b0} ^ ((crc_out[15] ^ data[0]) ? POLY : 16'h0);
                // Store remaining bits for next stages
                data_stage1 <= data[7:1];
            end else begin
                crc_stage1 <= crc_out;
                data_stage1 <= 7'h00;
            end
        end
    end
    
    // Stage 2: Process middle 3 bits
    always @(posedge clk) begin
        if (reset) begin
            crc_stage2 <= 16'h0000;
            data_stage2 <= 4'h0;
            req_stage2 <= 1'b0;
            calc_done_stage2 <= 1'b0;
        end else begin
            req_stage2 <= req_stage1;
            calc_done_stage2 <= calc_done_stage1;
            
            if (req_stage1) begin
                // 使用连续赋值避免阻塞复制问题
                reg [15:0] temp1, temp2, temp3;
                
                // Process bit 1
                temp1 = {crc_stage1[14:0], 1'b0} ^ ((crc_stage1[15] ^ data_stage1[0]) ? POLY : 16'h0);
                // Process bit 2
                temp2 = {temp1[14:0], 1'b0} ^ ((temp1[15] ^ data_stage1[1]) ? POLY : 16'h0);
                // Process bit 3
                temp3 = {temp2[14:0], 1'b0} ^ ((temp2[15] ^ data_stage1[2]) ? POLY : 16'h0);
                
                crc_stage2 <= temp3;
                // Store remaining bits
                data_stage2 <= data_stage1[6:3];
            end else begin
                crc_stage2 <= crc_stage1;
                data_stage2 <= 4'h0;
            end
        end
    end
    
    // Stage 3: Process last 4 bits
    always @(posedge clk) begin
        if (reset) begin
            crc_stage3 <= 16'h0000;
            req_stage3 <= 1'b0;
            calc_done_stage3 <= 1'b0;
        end else begin
            req_stage3 <= req_stage2;
            calc_done_stage3 <= calc_done_stage2;
            
            if (req_stage2) begin
                // 使用连续赋值避免阻塞复制问题
                reg [15:0] temp4, temp5, temp6, temp7;
                
                // Process bit 4
                temp4 = {crc_stage2[14:0], 1'b0} ^ ((crc_stage2[15] ^ data_stage2[0]) ? POLY : 16'h0);
                // Process bit 5
                temp5 = {temp4[14:0], 1'b0} ^ ((temp4[15] ^ data_stage2[1]) ? POLY : 16'h0);
                // Process bit 6
                temp6 = {temp5[14:0], 1'b0} ^ ((temp5[15] ^ data_stage2[2]) ? POLY : 16'h0);
                // Process bit 7
                temp7 = {temp6[14:0], 1'b0} ^ ((temp6[15] ^ data_stage2[3]) ? POLY : 16'h0);
                
                crc_stage3 <= temp7;
            end else begin
                crc_stage3 <= crc_stage2;
            end
        end
    end
    
    // Output stage: Final XOR when calculation is done
    always @(posedge clk) begin
        if (reset) begin
            crc_out <= 16'h0000;
        end else if (calc_done_stage3) begin
            crc_out <= crc_stage3 ^ FINAL_XOR;
        end else if (req_stage3) begin
            crc_out <= crc_stage3;
        end
    end
endmodule