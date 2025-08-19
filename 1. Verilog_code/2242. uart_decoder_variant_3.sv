//SystemVerilog
module uart_decoder #(parameter BAUD_RATE=9600) (
    input rx, clk, rst,
    output reg [7:0] data_out,
    output reg parity_err_out,
    output reg valid_out
);
    // 流水线阶段定义 - 减少为2个阶段
    localparam IDLE_STAGE = 1'b0;
    localparam ACTIVE_STAGE = 1'b1;
    
    // 阶段寄存器
    reg current_stage, next_stage;
    
    // 合并后的流水线 - 采样+处理阶段
    reg [3:0] sample_cnt;
    reg rx_sampled;
    reg sample_valid;
    reg [7:0] data_reg;
    wire mid_sample = (sample_cnt == 4'd7);
    
    // 状态控制
    reg processing_done;
    
    // 流水线控制
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            current_stage <= IDLE_STAGE;
        end else begin
            current_stage <= next_stage;
        end
    end
    
    // 阶段控制逻辑
    always @(*) begin
        next_stage = current_stage;
        
        case (current_stage)
            IDLE_STAGE: 
                if (rx == 1'b0) next_stage = ACTIVE_STAGE; // 开始位检测
                
            ACTIVE_STAGE:
                if (processing_done) next_stage = IDLE_STAGE;
                
            default:
                next_stage = IDLE_STAGE;
        endcase
    end
    
    // 合并的采样和处理流水线
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            sample_cnt <= 4'd0;
            rx_sampled <= 1'b1;
            sample_valid <= 1'b0;
            data_reg <= 8'd0;
            processing_done <= 1'b0;
        end else if (current_stage == ACTIVE_STAGE) begin
            rx_sampled <= rx;
            
            if (sample_cnt < 4'd15) begin
                sample_cnt <= sample_cnt + 4'd1;
                processing_done <= 1'b0;
            end else begin
                processing_done <= 1'b1;
            end
            
            if (mid_sample) begin
                sample_valid <= 1'b1;
                data_reg <= {rx_sampled, data_reg[7:1]};
            end else begin
                sample_valid <= 1'b0;
            end
        end else begin
            sample_cnt <= 4'd0;
            sample_valid <= 1'b0;
            processing_done <= 1'b0;
        end
    end
    
    // 输出逻辑 - 直接从处理阶段获取数据
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            data_out <= 8'd0;
            parity_err_out <= 1'b0;
            valid_out <= 1'b0;
        end else if (processing_done) begin
            data_out <= data_reg;
            parity_err_out <= ^data_reg ^ rx_sampled;
            valid_out <= 1'b1;
        end else begin
            valid_out <= 1'b0;
        end
    end
    
endmodule