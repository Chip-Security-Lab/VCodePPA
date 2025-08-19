//SystemVerilog
module usb_sof_generator(
    input wire clk,
    input wire rst_n,
    input wire sof_enable,
    input wire [10:0] frame_number_in,
    
    // Valid-Ready interface outputs
    output reg [10:0] frame_number_out,
    output reg sof_valid,
    input wire sof_ready,
    output reg [15:0] sof_packet
);
    reg [15:0] counter;
    reg sof_pending;
    reg [15:0] sof_packet_reg;
    reg [10:0] frame_number_reg;
    
    // 带状进位加法器信号
    wire [10:0] frame_number_next;
    wire [3:0] p_group; // 生成组信号
    wire [3:0] g_group; // 传播组信号
    wire [4:0] carry;   // 进位信号
    
    // 第一级：生成块进位生成和传播信号
    assign p_group[0] = frame_number_in[2] | frame_number_in[1] | frame_number_in[0];
    assign p_group[1] = frame_number_in[5] | frame_number_in[4] | frame_number_in[3];
    assign p_group[2] = frame_number_in[8] | frame_number_in[7] | frame_number_in[6];
    assign p_group[3] = frame_number_in[10] | frame_number_in[9];
    
    assign g_group[0] = (frame_number_in[2] & frame_number_in[1]) | 
                        (frame_number_in[2] & frame_number_in[0]) | 
                        (frame_number_in[1] & frame_number_in[0]);
    assign g_group[1] = (frame_number_in[5] & frame_number_in[4]) | 
                        (frame_number_in[5] & frame_number_in[3]) | 
                        (frame_number_in[4] & frame_number_in[3]);
    assign g_group[2] = (frame_number_in[8] & frame_number_in[7]) | 
                        (frame_number_in[8] & frame_number_in[6]) | 
                        (frame_number_in[7] & frame_number_in[6]);
    assign g_group[3] = frame_number_in[10] & frame_number_in[9];
    
    // 第二级：计算块间进位
    assign carry[0] = 1'b1; // 加1操作的初始进位
    assign carry[1] = g_group[0] | (p_group[0] & carry[0]);
    assign carry[2] = g_group[1] | (p_group[1] & carry[1]);
    assign carry[3] = g_group[2] | (p_group[2] & carry[2]);
    assign carry[4] = g_group[3] | (p_group[3] & carry[3]);
    
    // 计算最终结果
    assign frame_number_next[0] = frame_number_in[0] ^ 1'b1;
    assign frame_number_next[1] = frame_number_in[1] ^ carry[0];
    assign frame_number_next[2] = frame_number_in[2] ^ carry[0];
    
    assign frame_number_next[3] = frame_number_in[3] ^ carry[1];
    assign frame_number_next[4] = frame_number_in[4] ^ carry[1];
    assign frame_number_next[5] = frame_number_in[5] ^ carry[1];
    
    assign frame_number_next[6] = frame_number_in[6] ^ carry[2];
    assign frame_number_next[7] = frame_number_in[7] ^ carry[2];
    assign frame_number_next[8] = frame_number_in[8] ^ carry[2];
    
    assign frame_number_next[9] = frame_number_in[9] ^ carry[3];
    assign frame_number_next[10] = frame_number_in[10] ^ carry[3];
    
    // 计数器的带状进位加法器
    wire [15:0] counter_next;
    wire [4:0] pc_group; // 计数器的生成组信号
    wire [4:0] gc_group; // 计数器的传播组信号
    wire [5:0] c_carry;  // 计数器的进位信号
    
    // 第一级：生成块进位生成和传播信号
    assign pc_group[0] = counter[2] | counter[1] | counter[0];
    assign pc_group[1] = counter[5] | counter[4] | counter[3];
    assign pc_group[2] = counter[8] | counter[7] | counter[6];
    assign pc_group[3] = counter[11] | counter[10] | counter[9];
    assign pc_group[4] = counter[15] | counter[14] | counter[13] | counter[12];
    
    assign gc_group[0] = (counter[2] & counter[1]) | 
                         (counter[2] & counter[0]) | 
                         (counter[1] & counter[0]);
    assign gc_group[1] = (counter[5] & counter[4]) | 
                         (counter[5] & counter[3]) | 
                         (counter[4] & counter[3]);
    assign gc_group[2] = (counter[8] & counter[7]) | 
                         (counter[8] & counter[6]) | 
                         (counter[7] & counter[6]);
    assign gc_group[3] = (counter[11] & counter[10]) | 
                         (counter[11] & counter[9]) | 
                         (counter[10] & counter[9]);
    assign gc_group[4] = (counter[15] & counter[14]) | 
                         (counter[15] & counter[13]) | 
                         (counter[15] & counter[12]) | 
                         (counter[14] & counter[13]) | 
                         (counter[14] & counter[12]) | 
                         (counter[13] & counter[12]);
    
    // 第二级：计算块间进位
    assign c_carry[0] = 1'b1; // 加1操作的初始进位
    assign c_carry[1] = gc_group[0] | (pc_group[0] & c_carry[0]);
    assign c_carry[2] = gc_group[1] | (pc_group[1] & c_carry[1]);
    assign c_carry[3] = gc_group[2] | (pc_group[2] & c_carry[2]);
    assign c_carry[4] = gc_group[3] | (pc_group[3] & c_carry[3]);
    assign c_carry[5] = gc_group[4] | (pc_group[4] & c_carry[4]);
    
    // 计算计数器的下一个值
    assign counter_next[0] = counter[0] ^ 1'b1;
    assign counter_next[1] = counter[1] ^ c_carry[0];
    assign counter_next[2] = counter[2] ^ c_carry[0];
    
    assign counter_next[3] = counter[3] ^ c_carry[1];
    assign counter_next[4] = counter[4] ^ c_carry[1];
    assign counter_next[5] = counter[5] ^ c_carry[1];
    
    assign counter_next[6] = counter[6] ^ c_carry[2];
    assign counter_next[7] = counter[7] ^ c_carry[2];
    assign counter_next[8] = counter[8] ^ c_carry[2];
    
    assign counter_next[9] = counter[9] ^ c_carry[3];
    assign counter_next[10] = counter[10] ^ c_carry[3];
    assign counter_next[11] = counter[11] ^ c_carry[3];
    
    assign counter_next[12] = counter[12] ^ c_carry[4];
    assign counter_next[13] = counter[13] ^ c_carry[4];
    assign counter_next[14] = counter[14] ^ c_carry[4];
    assign counter_next[15] = counter[15] ^ c_carry[4];
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            counter <= 16'd0;
            frame_number_out <= 11'd0;
            frame_number_reg <= 11'd0;
            sof_valid <= 1'b0;
            sof_pending <= 1'b0;
            sof_packet <= 16'd0;
            sof_packet_reg <= 16'd0;
        end else begin
            // SOF generation every 1ms (assuming 48MHz clock)
            if (sof_enable) begin
                if (counter >= 16'd47999) begin
                    counter <= 16'd0;
                    frame_number_reg <= frame_number_next;
                    sof_pending <= 1'b1;
                    
                    // Generate SOF packet: PID (SOF) + frame number + CRC5
                    sof_packet_reg <= {5'b00000, frame_number_next}; // CRC calculation simplified
                end else begin
                    counter <= counter_next;
                end
            end
            
            // Valid-Ready handshake logic
            if (sof_pending) begin
                sof_valid <= 1'b1;
                sof_packet <= sof_packet_reg;
                frame_number_out <= frame_number_reg;
            end
            
            // Data transfer occurs when both valid and ready are high
            if (sof_valid && sof_ready) begin
                sof_valid <= 1'b0;
                sof_pending <= 1'b0;
            end
        end
    end
endmodule