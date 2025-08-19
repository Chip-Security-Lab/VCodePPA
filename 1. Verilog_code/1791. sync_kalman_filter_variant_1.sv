//SystemVerilog
module sync_kalman_filter #(
    parameter DATA_W = 16,
    parameter FRAC_BITS = 8
)(
    input clk, reset,
    input [DATA_W-1:0] measurement,
    input [DATA_W-1:0] process_noise,
    input [DATA_W-1:0] measurement_noise,
    output reg [DATA_W-1:0] estimate
);

    // 内部信号定义
    reg [DATA_W-1:0] prediction_stage1, prediction_stage2;
    reg [DATA_W-1:0] error_stage1, error_stage2, error_stage3;
    reg [DATA_W-1:0] gain_stage1, gain_stage2;
    reg [DATA_W-1:0] innovation_stage1, innovation_stage2;
    reg [2*DATA_W-1:0] gain_error_product_stage1, gain_error_product_stage2;
    reg [2*DATA_W-1:0] gain_innovation_product_stage1, gain_innovation_product_stage2;
    reg [2*DATA_W-1:0] error_sum_stage1, error_sum_stage2;
    reg [DATA_W-1:0] error_plus_meas_noise_stage1, error_plus_meas_noise_stage2;
    
    // 状态定义
    localparam PREDICT = 3'b000, 
               CALC_ERROR = 3'b001,
               CALC_GAIN = 3'b010,
               CALC_PRODUCTS = 3'b011,
               UPDATE = 3'b100;
    reg [2:0] state, next_state;
    
    // 状态控制
    always @(posedge clk) begin
        if (reset)
            state <= PREDICT;
        else
            state <= next_state;
    end
    
    always @(*) begin
        case (state)
            PREDICT:     next_state = CALC_ERROR;
            CALC_ERROR:  next_state = CALC_GAIN;
            CALC_GAIN:   next_state = CALC_PRODUCTS;
            CALC_PRODUCTS: next_state = UPDATE;
            UPDATE:      next_state = PREDICT;
            default:     next_state = PREDICT;
        endcase
    end
    
    // 数据处理
    always @(posedge clk) begin
        if (reset) begin
            prediction_stage1 <= 0;
            prediction_stage2 <= 0;
            estimate <= 0;
            error_stage1 <= measurement_noise;
            error_stage2 <= measurement_noise;
            error_stage3 <= measurement_noise;
            gain_stage1 <= 0;
            gain_stage2 <= 0;
            innovation_stage1 <= 0;
            innovation_stage2 <= 0;
            gain_error_product_stage1 <= 0;
            gain_error_product_stage2 <= 0;
            gain_innovation_product_stage1 <= 0;
            gain_innovation_product_stage2 <= 0;
            error_sum_stage1 <= 0;
            error_sum_stage2 <= 0;
            error_plus_meas_noise_stage1 <= 0;
            error_plus_meas_noise_stage2 <= 0;
        end else begin
            case (state)
                PREDICT: begin
                    prediction_stage1 <= estimate;
                    error_sum_stage1 <= error_stage3 + process_noise;
                    innovation_stage1 <= measurement - prediction_stage1;
                end
                
                CALC_ERROR: begin
                    error_stage1 <= error_sum_stage1[DATA_W-1:0];
                    error_plus_meas_noise_stage1 <= error_sum_stage1[DATA_W-1:0] + measurement_noise;
                    prediction_stage2 <= prediction_stage1;
                    innovation_stage2 <= innovation_stage1;
                end
                
                CALC_GAIN: begin
                    if (error_stage1 >= measurement_noise) begin
                        gain_stage1 <= ((error_stage1 << FRAC_BITS) / 
                                     (error_plus_meas_noise_stage1));
                    end else begin
                        gain_stage1 <= ((error_stage1 << FRAC_BITS) / 
                                     (error_plus_meas_noise_stage1));
                    end
                    error_stage2 <= error_stage1;
                end
                
                CALC_PRODUCTS: begin
                    gain_innovation_product_stage1 <= gain_stage1 * innovation_stage2;
                    gain_error_product_stage1 <= ((1 << FRAC_BITS) - gain_stage1) * error_stage2;
                    gain_stage2 <= gain_stage1;
                end
                
                UPDATE: begin
                    estimate <= prediction_stage2 + (gain_innovation_product_stage1 >> FRAC_BITS);
                    error_stage3 <= gain_error_product_stage1 >> FRAC_BITS;
                end
            endcase
        end
    end
endmodule