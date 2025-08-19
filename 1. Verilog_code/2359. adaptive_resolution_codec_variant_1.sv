//SystemVerilog
module adaptive_resolution_codec (
    input  wire        clk,
    input  wire        rst_n,
    input  wire [23:0] pixel_in,
    input  wire [1:0]  resolution_mode,  // 0: Full, 1: Half, 2: Quarter
    input  wire        data_valid,
    input  wire        line_end,
    input  wire        frame_end,
    output wire [15:0] pixel_out,
    output wire        out_valid
);

    // 内部信号连接
    wire [1:0]  x_cnt, y_cnt;
    wire [23:0] pixel_sum_r, pixel_sum_g, pixel_sum_b;
    wire [3:0]  pixel_count;
    wire        accumulation_done;

    // 坐标计数器子模块
    position_counter position_counter_inst (
        .clk          (clk),
        .rst_n        (rst_n),
        .data_valid   (data_valid),
        .line_end     (line_end),
        .frame_end    (frame_end),
        .x_cnt        (x_cnt),
        .y_cnt        (y_cnt)
    );

    // 像素累加器子模块
    pixel_accumulator pixel_accumulator_inst (
        .clk             (clk),
        .rst_n           (rst_n),
        .data_valid      (data_valid),
        .resolution_mode (resolution_mode),
        .pixel_in        (pixel_in),
        .x_cnt           (x_cnt),
        .y_cnt           (y_cnt),
        .pixel_sum_r     (pixel_sum_r),
        .pixel_sum_g     (pixel_sum_g),
        .pixel_sum_b     (pixel_sum_b),
        .pixel_count     (pixel_count),
        .accumulation_done (accumulation_done)
    );

    // 输出处理器子模块
    output_processor output_processor_inst (
        .clk             (clk),
        .rst_n           (rst_n),
        .data_valid      (data_valid),
        .resolution_mode (resolution_mode),
        .pixel_in        (pixel_in),
        .pixel_sum_r     (pixel_sum_r),
        .pixel_sum_g     (pixel_sum_g),
        .pixel_sum_b     (pixel_sum_b),
        .pixel_count     (pixel_count),
        .accumulation_done (accumulation_done),
        .pixel_out       (pixel_out),
        .out_valid       (out_valid)
    );

endmodule

// 坐标计数器子模块
module position_counter (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       data_valid,
    input  wire       line_end,
    input  wire       frame_end,
    output reg  [1:0] x_cnt,
    output reg  [1:0] y_cnt
);

    // 位置计数器控制逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            x_cnt <= 2'd0;
            y_cnt <= 2'd0;
        end else begin
            if (frame_end) begin
                x_cnt <= 2'd0;
                y_cnt <= 2'd0;
            end else if (line_end) begin
                x_cnt <= 2'd0;
                y_cnt <= (y_cnt == 2'd3) ? 2'd0 : y_cnt + 2'd1;
            end else if (data_valid) begin
                x_cnt <= (x_cnt == 2'd3) ? 2'd0 : x_cnt + 2'd1;
            end
        end
    end

endmodule

// 像素累加器子模块
module pixel_accumulator (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        data_valid,
    input  wire [1:0]  resolution_mode,
    input  wire [23:0] pixel_in,
    input  wire [1:0]  x_cnt,
    input  wire [1:0]  y_cnt,
    output reg  [23:0] pixel_sum_r,
    output reg  [23:0] pixel_sum_g,
    output reg  [23:0] pixel_sum_b,
    output reg  [3:0]  pixel_count,
    output wire        accumulation_done
);

    // 定义状态信号
    wire half_res_start, quarter_res_start;
    wire half_res_done, quarter_res_done;

    // 累加开始条件
    assign half_res_start = (resolution_mode == 2'b01) && (y_cnt[0] == 1'b0) && (x_cnt[0] == 1'b0);
    assign quarter_res_start = (resolution_mode == 2'b10) && (y_cnt == 2'd0) && (x_cnt == 2'd0);
    
    // 累加完成条件
    assign half_res_done = (resolution_mode == 2'b01) && (pixel_count == 4'd3);
    assign quarter_res_done = (resolution_mode == 2'b10) && (pixel_count == 4'd15);
    
    // 暴露累加完成信号给外部模块
    assign accumulation_done = half_res_done || quarter_res_done;

    // 像素累加器控制逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pixel_sum_r <= 24'd0;
            pixel_sum_g <= 24'd0;
            pixel_sum_b <= 24'd0;
            pixel_count <= 4'd0;
        end else if (data_valid) begin
            case (resolution_mode)
                2'b01: begin // 半分辨率（2x2平均）
                    if (half_res_start) begin
                        pixel_sum_r <= pixel_in[23:16];
                        pixel_sum_g <= pixel_in[15:8];
                        pixel_sum_b <= pixel_in[7:0];
                        pixel_count <= 4'd1;
                    end else begin
                        pixel_sum_r <= pixel_sum_r + pixel_in[23:16];
                        pixel_sum_g <= pixel_sum_g + pixel_in[15:8];
                        pixel_sum_b <= pixel_sum_b + pixel_in[7:0];
                        pixel_count <= pixel_count + 4'd1;
                        
                        if (half_res_done) begin
                            pixel_count <= 4'd0;
                        end
                    end
                end
                2'b10: begin // 四分之一分辨率（4x4平均）
                    if (quarter_res_start) begin
                        pixel_sum_r <= pixel_in[23:16];
                        pixel_sum_g <= pixel_in[15:8];
                        pixel_sum_b <= pixel_in[7:0];
                        pixel_count <= 4'd1;
                    end else begin
                        pixel_sum_r <= pixel_sum_r + pixel_in[23:16];
                        pixel_sum_g <= pixel_sum_g + pixel_in[15:8];
                        pixel_sum_b <= pixel_sum_b + pixel_in[7:0];
                        pixel_count <= pixel_count + 4'd1;
                        
                        if (quarter_res_done) begin
                            pixel_count <= 4'd0;
                        end
                    end
                end
                default: begin
                    // 对于全分辨率模式，不需要累加
                    pixel_sum_r <= 24'd0;
                    pixel_sum_g <= 24'd0;
                    pixel_sum_b <= 24'd0;
                    pixel_count <= 4'd0;
                end
            endcase
        end
    end

endmodule

// 输出处理器子模块
module output_processor (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        data_valid,
    input  wire [1:0]  resolution_mode,
    input  wire [23:0] pixel_in,
    input  wire [23:0] pixel_sum_r,
    input  wire [23:0] pixel_sum_g,
    input  wire [23:0] pixel_sum_b,
    input  wire [3:0]  pixel_count,
    input  wire        accumulation_done,
    output reg  [15:0] pixel_out,
    output reg         out_valid
);

    // 输出控制逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pixel_out <= 16'd0;
            out_valid <= 1'b0;
        end else begin
            // 默认无效输出
            out_valid <= 1'b0;
            
            if (data_valid) begin
                case (resolution_mode)
                    2'b00: begin // 全分辨率
                        pixel_out <= {pixel_in[23:19], pixel_in[15:10], pixel_in[7:3]};
                        out_valid <= 1'b1;
                    end
                    2'b01: begin // 半分辨率
                        if (pixel_count == 4'd3) begin
                            // 平均并输出
                            pixel_out <= {pixel_sum_r[9:5] + pixel_in[23:19], 
                                         pixel_sum_g[9:4] + pixel_in[15:10], 
                                         pixel_sum_b[9:5] + pixel_in[7:3]};
                            out_valid <= 1'b1;
                        end
                    end
                    2'b10: begin // 四分之一分辨率
                        if (pixel_count == 4'd15) begin
                            // 平均并输出
                            pixel_out <= {pixel_sum_r[11:7] + pixel_in[23:19], 
                                         pixel_sum_g[11:6] + pixel_in[15:10], 
                                         pixel_sum_b[11:7] + pixel_in[7:3]};
                            out_valid <= 1'b1;
                        end
                    end
                    default: begin
                        // 通透传递
                        pixel_out <= {pixel_in[23:19], pixel_in[15:10], pixel_in[7:3]};
                        out_valid <= 1'b1;
                    end
                endcase
            end
        end
    end

endmodule