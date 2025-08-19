//SystemVerilog
module dual_clock_timer (
    // Clock and reset
    input wire clk_fast,
    input wire clk_slow,
    input wire reset_n,
    
    // AXI-Stream input interface
    input wire [15:0] s_axis_tdata,  // Target value input
    input wire s_axis_tvalid,
    output wire s_axis_tready,
    
    // AXI-Stream output interface
    output wire [0:0] m_axis_tdata,  // Tick output
    output reg m_axis_tvalid,
    input wire m_axis_tready,
    output reg m_axis_tlast
);
    reg [15:0] counter_fast;
    reg match_detected;
    reg [1:0] sync_reg;
    reg [15:0] target;
    reg target_updated;
    reg output_pulse;
    
    // 优化：直接接收输入数据，无需额外寄存器延迟
    // Input AXI-Stream interface handshaking
    assign s_axis_tready = 1'b1;  // Always ready to accept new target values
    
    // 优化：将目标值的逻辑和比较计算提前处理
    wire [15:0] next_target = s_axis_tvalid ? s_axis_tdata : target;
    wire next_target_updated = s_axis_tvalid && s_axis_tready;
    wire [15:0] next_counter = target_updated ? 16'h0000 : (counter_fast + 1'b1);
    wire next_match_detected = (next_counter == next_target - 1'b1);
    
    // Fast clock domain: counter and match detection
    always @(posedge clk_fast or negedge reset_n) begin
        if (!reset_n) begin
            target <= 16'h0000;
            target_updated <= 1'b0;
            counter_fast <= 16'h0000;
            match_detected <= 1'b0;
        end else begin
            target <= next_target;
            target_updated <= next_target_updated;
            counter_fast <= next_counter;
            match_detected <= next_match_detected;
        end
    end
    
    // 优化：将脉冲检测提前，减少慢时钟域的组合逻辑
    wire next_sync_0 = match_detected;
    wire next_sync_1 = sync_reg[0];
    wire next_output_pulse = next_sync_0 & ~next_sync_1;
    
    // Slow clock domain: synchronization and pulse generation
    always @(posedge clk_slow or negedge reset_n) begin
        if (!reset_n) begin
            sync_reg <= 2'b00;
            output_pulse <= 1'b0;
            m_axis_tvalid <= 1'b0;
            m_axis_tlast <= 1'b0;
        end else begin
            sync_reg <= {next_sync_1, next_sync_0};
            output_pulse <= next_output_pulse;
            
            // AXI-Stream output handshaking
            if (next_output_pulse && !m_axis_tvalid) begin
                m_axis_tvalid <= 1'b1;
                m_axis_tlast <= 1'b1;  // Indicate the end of transaction
            end else if (m_axis_tvalid && m_axis_tready) begin
                m_axis_tvalid <= 1'b0;
                m_axis_tlast <= 1'b0;
            end
        end
    end
    
    // Connect output pulse to tdata
    assign m_axis_tdata = output_pulse;

endmodule