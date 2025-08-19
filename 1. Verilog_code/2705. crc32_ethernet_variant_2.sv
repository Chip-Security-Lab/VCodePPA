//SystemVerilog
module crc32_ethernet (
    input clk, rst,
    input req,           // 请求信号，替换原valid信号
    input [31:0] data_in,
    output reg ack,      // 应答信号，替换原ready信号
    output reg [31:0] crc_out
);
    parameter POLY = 32'h04C11DB7;
    
    // 状态机定义
    localparam IDLE = 1'b0;
    localparam BUSY = 1'b1;
    reg state, next_state;
    
    // 数据处理标志
    reg data_valid;
    reg processing_done;
    
    // Stage 1: Bit reversal
    reg [31:0] data_rev_stage1;
    integer i;
    
    always @(posedge clk) begin
        if (rst) begin
            data_rev_stage1 <= 32'h0;
            data_valid <= 1'b0;
            ack <= 1'b0;
            state <= IDLE;
        end else begin
            state <= next_state;
            
            case(state)
                IDLE: begin
                    if (req) begin
                        // 接收数据并发送确认
                        for (i = 0; i < 32; i = i + 1) begin
                            data_rev_stage1[i] <= data_in[31-i]; // 使用循环进行位翻转
                        end
                        data_valid <= 1'b1;
                        ack <= 1'b1; // 确认接收数据
                    end else begin
                        ack <= 1'b0;
                        data_valid <= 1'b0;
                    end
                end
                
                BUSY: begin
                    ack <= 1'b0; // 复位确认信号
                    data_valid <= 1'b0;
                    
                    if (processing_done) begin
                        // 处理完成，可以接收新数据
                    end
                end
            endcase
        end
    end
    
    // Next state logic
    always @(*) begin
        next_state = state;
        
        case(state)
            IDLE: begin
                if (req) next_state = BUSY;
            end
            
            BUSY: begin
                if (processing_done) next_state = IDLE;
            end
        endcase
    end

    // Stage 2: XOR operation
    reg [31:0] crc_xord_stage2;
    always @(posedge clk) begin
        if (rst) 
            crc_xord_stage2 <= 32'h0;
        else if (data_valid) 
            crc_xord_stage2 <= crc_out ^ data_rev_stage1;
    end

    // Stage 3: First half of CRC calculation
    reg [15:0] next_val_stage3;
    always @(posedge clk) begin
        if (rst) 
            next_val_stage3 <= 16'h0;
        else if (data_valid || state == BUSY) begin
            for (i = 0; i < 16; i = i + 1) begin
                next_val_stage3[i] <= crc_xord_stage2[31] ^ 
                                     (i > 0 ? crc_xord_stage2[i-1] : 1'b0) ^ 
                                     (POLY[i] & crc_xord_stage2[31]);
            end
        end
    end

    // Stage 4: Second half of CRC calculation
    reg [15:0] next_val_stage4;
    always @(posedge clk) begin
        if (rst) 
            next_val_stage4 <= 16'h0;
        else if (data_valid || state == BUSY) begin
            for (i = 0; i < 16; i = i + 1) begin
                next_val_stage4[i] <= crc_xord_stage2[31] ^ 
                                     crc_xord_stage2[i+16] ^ 
                                     (POLY[i+16] & crc_xord_stage2[31]);
            end
        end
    end

    // Stage 5: Final CRC output and processing completion flag
    always @(posedge clk) begin
        if (rst) begin
            crc_out <= 32'hFFFFFFFF;
            processing_done <= 1'b0;
        end
        else if (data_valid || state == BUSY) begin
            crc_out <= {next_val_stage4, next_val_stage3};
            processing_done <= 1'b1;
        end
        else if (state == IDLE) begin
            processing_done <= 1'b0;
        end
    end
endmodule