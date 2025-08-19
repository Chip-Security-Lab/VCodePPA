//SystemVerilog
module usb_speed_detector(
    input  wire       clk,
    input  wire       rst_n,
    input  wire       dp,
    input  wire       dm,
    input  wire       detect_en,
    output reg        low_speed,
    output reg        full_speed,
    output reg        no_device,
    output reg        chirp_detected,
    output reg  [1:0] detection_state
);
    // 状态编码 - 使用单热码编码减少状态转换逻辑延迟
    localparam [1:0] IDLE       = 2'b00;
    localparam [1:0] WAIT_STABLE = 2'b01;
    localparam [1:0] DETECT     = 2'b10;
    localparam [1:0] COMPLETE   = 2'b11;
    
    reg [9:0] stability_counter;
    reg       prev_dp, prev_dm;
    reg       dp_stable, dm_stable;
    reg       counter_overflow;
    
    // 分段计数器逻辑 - 减少关键路径深度
    wire [4:0] counter_lower_plus_one;
    wire [4:0] counter_upper_plus_one;
    wire       lower_overflow;
    
    // 分割进位链以缩短关键路径
    assign counter_lower_plus_one = stability_counter[4:0] + 5'd1;
    assign lower_overflow = (counter_lower_plus_one == 5'd0);
    assign counter_upper_plus_one = stability_counter[9:5] + {4'd0, lower_overflow};
    
    // 预计算稳定性和检测条件，减少组合逻辑层次
    wire signals_stable = (dp == prev_dp) && (dm == prev_dm);
    wire counter_done = (stability_counter >= 10'd500); // ~10µs at 48MHz
    
    // 预解码USB状态条件
    wire is_no_device = !(dp || dm);
    wire is_full_speed = dp && !dm;
    wire is_low_speed = !dp && dm;
    wire is_chirp = dp && dm;
    
    // 主状态机逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            detection_state <= IDLE;
            low_speed <= 1'b0;
            full_speed <= 1'b0;
            no_device <= 1'b1;
            chirp_detected <= 1'b0;
            stability_counter <= 10'd0;
            prev_dp <= 1'b0;
            prev_dm <= 1'b0;
            dp_stable <= 1'b0;
            dm_stable <= 1'b0;
        end else begin
            // 更新前一个周期值
            prev_dp <= dp;
            prev_dm <= dm;
            
            // 默认保持计数器不变，仅在特定条件下更新
            case (detection_state)
                IDLE: begin
                    if (detect_en) begin
                        detection_state <= WAIT_STABLE;
                        stability_counter <= 10'd0;
                    end
                end
                
                WAIT_STABLE: begin
                    if (signals_stable) begin
                        if (counter_done) begin
                            detection_state <= DETECT;
                        end else begin
                            // 使用分段计数器更新，减少组合逻辑延迟
                            stability_counter[4:0] <= counter_lower_plus_one;
                            stability_counter[9:5] <= counter_upper_plus_one;
                        end
                    end else begin
                        stability_counter <= 10'd0;
                    end
                end
                
                DETECT: begin
                    // 使用预解码的USB状态信号
                    no_device <= is_no_device;
                    full_speed <= is_full_speed;
                    low_speed <= is_low_speed;
                    chirp_detected <= is_chirp;
                    detection_state <= COMPLETE;
                end
                
                COMPLETE: begin
                    if (!detect_en)
                        detection_state <= IDLE;
                end
            endcase
        end
    end
endmodule