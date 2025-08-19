//SystemVerilog
module manchester_decoder (
    input  wire        clk,           // Oversampling clock (4x data rate)
    input  wire        rst_n,
    input  wire        manchester_in,
    input  wire        polarity,      // 0=rising=1, 1=falling=0
    output reg         data_out,
    output reg         data_valid,
    output reg         clock_recovered
);
    // 状态定义
    localparam IDLE = 2'b00, FIRST_HALF = 2'b01, SECOND_HALF = 2'b10;
    
    // 阶段1: 边沿检测和采样
    reg [1:0] state_stage1;
    reg [1:0] sample_cnt_stage1;
    reg manchester_in_stage1, prev_sample_stage1;
    reg polarity_stage1;
    reg edge_detected_stage1;
    
    // 阶段2: 位值提取
    reg [1:0] state_stage2;
    reg [1:0] sample_cnt_stage2;
    reg manchester_in_stage2, polarity_stage2;
    reg bit_value_stage2;
    reg valid_stage2;
    reg clock_recovered_stage2;
    
    // 阶段3: 输出生成
    reg bit_value_stage3;
    reg valid_stage3;
    reg clock_recovered_stage3;
    
    // 中间变量
    reg edge_detected;
    reg first_half_complete;
    reg second_half_complete;
    reg bit_value;
    
    // 阶段1: 边沿检测和采样
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state_stage1 <= IDLE;
            sample_cnt_stage1 <= 2'b00;
            manchester_in_stage1 <= 1'b0;
            prev_sample_stage1 <= 1'b0;
            polarity_stage1 <= 1'b0;
            edge_detected_stage1 <= 1'b0;
        end else begin
            manchester_in_stage1 <= manchester_in;
            prev_sample_stage1 <= manchester_in_stage1;
            polarity_stage1 <= polarity;
            edge_detected_stage1 <= (manchester_in_stage1 != prev_sample_stage1);
            
            case (state_stage1)
                IDLE: begin
                    if (manchester_in_stage1 != prev_sample_stage1) begin
                        state_stage1 <= FIRST_HALF;
                        sample_cnt_stage1 <= 2'b00;
                    end
                end
                
                FIRST_HALF: begin
                    if (sample_cnt_stage1 == 2'b01) begin
                        state_stage1 <= SECOND_HALF;
                        sample_cnt_stage1 <= 2'b00;
                    end else
                        sample_cnt_stage1 <= sample_cnt_stage1 + 1'b1;
                end
                
                SECOND_HALF: begin
                    if (sample_cnt_stage1 == 2'b01) begin
                        state_stage1 <= FIRST_HALF;
                        sample_cnt_stage1 <= 2'b00;
                    end else
                        sample_cnt_stage1 <= sample_cnt_stage1 + 1'b1;
                end
                
                default: state_stage1 <= IDLE;
            endcase
        end
    end
    
    // 阶段2: 位值提取
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state_stage2 <= IDLE;
            sample_cnt_stage2 <= 2'b00;
            manchester_in_stage2 <= 1'b0;
            polarity_stage2 <= 1'b0;
            bit_value_stage2 <= 1'b0;
            valid_stage2 <= 1'b0;
            clock_recovered_stage2 <= 1'b0;
        end else begin
            state_stage2 <= state_stage1;
            sample_cnt_stage2 <= sample_cnt_stage1;
            manchester_in_stage2 <= manchester_in_stage1;
            polarity_stage2 <= polarity_stage1;
            valid_stage2 <= 1'b0;
            
            // 位值提取逻辑
            if (state_stage1 == FIRST_HALF && sample_cnt_stage1 == 2'b01) begin
                bit_value_stage2 <= polarity_stage1 ? ~manchester_in_stage1 : manchester_in_stage1;
                clock_recovered_stage2 <= 1'b1;
            end
            
            // 数据有效信号生成
            if (state_stage1 == SECOND_HALF && sample_cnt_stage1 == 2'b01) begin
                valid_stage2 <= 1'b1;
            end
        end
    end
    
    // 阶段3: 输出生成
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_out <= 1'b0;
            data_valid <= 1'b0;
            clock_recovered <= 1'b0;
            bit_value_stage3 <= 1'b0;
            valid_stage3 <= 1'b0;
            clock_recovered_stage3 <= 1'b0;
        end else begin
            bit_value_stage3 <= bit_value_stage2;
            valid_stage3 <= valid_stage2;
            clock_recovered_stage3 <= clock_recovered_stage2;
            
            // 输出寄存器更新
            data_out <= bit_value_stage3;
            data_valid <= valid_stage3;
            clock_recovered <= clock_recovered_stage3;
        end
    end
endmodule