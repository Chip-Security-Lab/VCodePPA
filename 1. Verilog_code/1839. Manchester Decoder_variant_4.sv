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
    reg [1:0] state;
    reg [1:0] sample_cnt;
    reg manchester_in_reg;
    reg polarity_reg;
    reg transition_detected;
    
    localparam IDLE = 2'b00, FIRST_HALF = 2'b01, SECOND_HALF = 2'b10;
    
    // 首先寄存输入信号，减少输入到第一级寄存器的路径延迟
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            manchester_in_reg <= 1'b0;
            polarity_reg <= 1'b0;
        end else begin
            manchester_in_reg <= manchester_in;
            polarity_reg <= polarity;
        end
    end
    
    // 计算转换检测信号，提前进行组合逻辑计算
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            transition_detected <= 1'b0;
        end else begin
            transition_detected <= (manchester_in_reg != manchester_in);
        end
    end
    
    // 主状态机逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            sample_cnt <= 2'b00;
            data_out <= 1'b0;
            data_valid <= 1'b0;
            clock_recovered <= 1'b0;
        end else begin
            data_valid <= 1'b0;
            
            case (state)
                IDLE: begin
                    if (transition_detected) begin
                        state <= FIRST_HALF;
                        sample_cnt <= 2'b00;
                    end
                end
                
                FIRST_HALF: begin
                    if (sample_cnt == 2'b01) begin
                        state <= SECOND_HALF;
                        // 使用寄存的极性信号和输入信号
                        data_out <= polarity_reg ? ~manchester_in_reg : manchester_in_reg;
                        clock_recovered <= 1'b1;
                    end else
                        sample_cnt <= sample_cnt + 1'b1;
                end
                
                SECOND_HALF: begin
                    if (sample_cnt == 2'b01) begin
                        state <= FIRST_HALF;
                        data_valid <= 1'b1;
                        sample_cnt <= 2'b00;
                    end else
                        sample_cnt <= sample_cnt + 1'b1;
                end
                
                default: state <= IDLE;
            endcase
        end
    end
endmodule