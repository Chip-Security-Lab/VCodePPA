//SystemVerilog
//IEEE 1364-2005
module usb_hs_negotiation(
    input wire clk,
    input wire rst_n,
    input wire chirp_start,
    input wire dp_in,
    input wire dm_in,
    output reg dp_out,
    output reg dm_out,
    output reg dp_oe,
    output reg dm_oe,
    output reg hs_detected,
    output reg [2:0] chirp_state,
    output reg [1:0] speed_status
);
    // Chirp state machine states
    localparam IDLE = 3'd0;
    localparam K_CHIRP = 3'd1;
    localparam J_DETECT = 3'd2;
    localparam K_DETECT = 3'd3;
    localparam HANDSHAKE = 3'd4;
    localparam COMPLETE = 3'd5;
    
    // Speed status values
    localparam FULLSPEED = 2'd0;
    localparam HIGHSPEED = 2'd1;
    
    reg [15:0] chirp_counter;
    reg [2:0] kj_count;
    
    // 输入信号的寄存器
    reg chirp_start_r;
    reg dp_in_r, dm_in_r;
    
    // 输入信号前向寄存器
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            chirp_start_r <= 1'b0;
            dp_in_r <= 1'b0;
            dm_in_r <= 1'b0;
        end else begin
            chirp_start_r <= chirp_start;
            dp_in_r <= dp_in;
            dm_in_r <= dm_in;
        end
    end
    
    // 状态转换和计数器控制
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            chirp_state <= IDLE;
            chirp_counter <= 16'd0;
            kj_count <= 3'd0;
        end else begin
            case (chirp_state)
                IDLE: begin
                    if (chirp_start_r) begin
                        chirp_state <= K_CHIRP;
                        chirp_counter <= 16'd0;
                    end
                end
                
                K_CHIRP: begin
                    chirp_counter <= chirp_counter + 16'd1;
                    if (chirp_counter >= 16'd7500) begin  // ~156.25µs for K chirp
                        chirp_state <= J_DETECT;
                        kj_count <= 3'd0;
                        chirp_counter <= 16'd0;
                    end
                end
                
                J_DETECT: begin
                    chirp_counter <= chirp_counter + 16'd1;
                    if (dp_in_r && !dm_in_r) begin  // J detected
                        kj_count <= kj_count + 1'b1;
                        chirp_state <= K_DETECT;
                        chirp_counter <= 16'd0;
                    end else if (chirp_counter >= 16'd15000) begin  // Timeout
                        chirp_state <= IDLE;
                    end
                end
                
                K_DETECT: begin
                    chirp_counter <= chirp_counter + 16'd1;
                    if (!dp_in_r && dm_in_r) begin  // K detected
                        kj_count <= kj_count + 1'b1;
                        chirp_state <= J_DETECT;
                        chirp_counter <= 16'd0;
                        
                        if (kj_count >= 3'd5) begin  // At least 6 KJ pairs
                            chirp_state <= HANDSHAKE;
                            chirp_counter <= 16'd0;
                        end
                    end else if (chirp_counter >= 16'd15000) begin  // Timeout
                        chirp_state <= IDLE;
                    end
                end
                
                HANDSHAKE: begin
                    chirp_counter <= chirp_counter + 16'd1;
                    if (chirp_counter >= 16'd5000) begin
                        chirp_state <= COMPLETE;
                    end
                end
                
                COMPLETE: begin
                    // Stay in complete state until reset or new chirp_start
                    if (chirp_start_r) begin
                        chirp_state <= IDLE;
                    end
                end
                
                default: chirp_state <= IDLE;
            endcase
        end
    end
    
    // 速度状态控制 - 提前计算下一阶段
    reg [1:0] next_speed_status;
    reg next_hs_detected;
    
    always @(*) begin
        next_speed_status = speed_status;
        next_hs_detected = hs_detected;
        
        case (chirp_state)
            IDLE: begin
                next_speed_status = FULLSPEED;
                next_hs_detected = 1'b0;
            end
            
            HANDSHAKE: begin
                next_speed_status = HIGHSPEED;
            end
            
            COMPLETE: begin
                next_hs_detected = 1'b1;
            end
            
            default: begin
                // 保持当前状态
            end
        endcase
    end
    
    // 速度状态寄存控制
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            speed_status <= FULLSPEED;
            hs_detected <= 1'b0;
        end else begin
            speed_status <= next_speed_status;
            hs_detected <= next_hs_detected;
        end
    end
    
    // 输出信号前向推算
    reg dp_out_next, dm_out_next;
    reg dp_oe_next, dm_oe_next;
    
    always @(*) begin
        dp_out_next = dp_out;
        dm_out_next = dm_out;
        dp_oe_next = dp_oe;
        dm_oe_next = dm_oe;
        
        case (chirp_state)
            IDLE: begin
                if (chirp_start_r) begin
                    dp_out_next = 1'b0;  // K state chirp
                    dm_out_next = 1'b1;
                    dp_oe_next = 1'b1;
                    dm_oe_next = 1'b1;
                end else begin
                    dp_out_next = 1'b1;  // J state (fullspeed idle)
                    dm_out_next = 1'b0;
                    dp_oe_next = 1'b0;
                    dm_oe_next = 1'b0;
                end
            end
            
            K_CHIRP: begin
                dp_out_next = 1'b0;  // K state chirp
                dm_out_next = 1'b1;
                dp_oe_next = 1'b1;
                dm_oe_next = 1'b1;
                
                if (chirp_counter >= 16'd7500) begin
                    dp_oe_next = 1'b0;
                    dm_oe_next = 1'b0;
                end
            end
            
            J_DETECT, K_DETECT: begin
                dp_oe_next = 1'b0;
                dm_oe_next = 1'b0;
            end
            
            HANDSHAKE: begin
                dp_out_next = 1'b0;  // SE0 for high-speed
                dm_out_next = 1'b0;
                dp_oe_next = 1'b1;
                dm_oe_next = 1'b1;
            end
            
            COMPLETE: begin
                if (speed_status == HIGHSPEED) begin
                    dp_out_next = 1'b0;  // SE0 for high-speed
                    dm_out_next = 1'b0;
                end else begin
                    dp_out_next = 1'b1;  // J state (fullspeed idle)
                    dm_out_next = 1'b0;
                end
                dp_oe_next = 1'b1;
                dm_oe_next = 1'b1;
            end
            
            default: begin
                dp_oe_next = 1'b0;
                dm_oe_next = 1'b0;
            end
        endcase
    end
    
    // 输出信号寄存控制
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            dp_out <= 1'b1;  // J state (fullspeed idle)
            dm_out <= 1'b0;
            dp_oe <= 1'b0;
            dm_oe <= 1'b0;
        end else begin
            dp_out <= dp_out_next;
            dm_out <= dm_out_next;
            dp_oe <= dp_oe_next;
            dm_oe <= dm_oe_next;
        end
    end
    
endmodule