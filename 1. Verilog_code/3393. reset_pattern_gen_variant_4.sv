//SystemVerilog
//IEEE 1364-2005 Verilog
module reset_pattern_gen(
    input wire clk,
    input wire rst_n,             // Added reset signal
    input wire trigger,
    input wire [7:0] pattern,
    input wire in_ready,          // Added ready signal from downstream
    output wire [7:0] reset_seq,  // Changed to wire
    output wire out_valid         // Added valid signal
);
    // Stage 1: Bit position control and increment logic
    reg [2:0] bit_pos_stage1;
    reg valid_stage1;
    reg [7:0] pattern_stage1;
    
    // Stage 2: Reset sequence generation
    reg [2:0] bit_pos_stage2;
    reg valid_stage2;
    reg [7:0] pattern_stage2;
    reg [7:0] reset_seq_stage2;
    reg out_valid_reg;            // Added valid register
    reg [7:0] reset_seq_reg;      // Added output register
    
    // 跳跃进位加法器信号
    wire [3:0] p, g; // 传播和生成信号
    wire [3:0] c;    // 进位信号
    wire [2:0] sum;  // 求和结果
    
    // Handshaking and flow control signals
    wire stage1_ready;
    wire stage2_ready;
    wire stage1_valid_and_ready;
    wire stage2_valid_and_ready;
    
    // 生成传播和生成信号
    assign p[0] = bit_pos_stage1[0];
    assign g[0] = 1'b0;
    assign p[1] = bit_pos_stage1[1];
    assign g[1] = 1'b0;
    assign p[2] = bit_pos_stage1[2];
    assign g[2] = 1'b0;
    assign p[3] = 1'b0;
    assign g[3] = 1'b0;
    
    // 计算进位
    assign c[0] = 1'b1; // 初始进位为1（用于+1操作）
    assign c[1] = g[0] | (p[0] & c[0]);
    assign c[2] = g[1] | (p[1] & g[0]) | (p[1] & p[0] & c[0]);
    assign c[3] = g[2] | (p[2] & g[1]) | (p[2] & p[1] & g[0]) | (p[2] & p[1] & p[0] & c[0]);
    
    // 计算求和
    assign sum[0] = p[0] ^ c[0];
    assign sum[1] = p[1] ^ c[1];
    assign sum[2] = p[2] ^ c[2];
    
    // Handshaking logic
    assign stage2_ready = in_ready || !out_valid_reg; 
    assign stage1_ready = stage2_ready;
    assign stage1_valid_and_ready = valid_stage1 && stage1_ready;
    assign stage2_valid_and_ready = valid_stage2 && stage2_ready;
    
    // Connect outputs
    assign reset_seq = reset_seq_reg;
    assign out_valid = out_valid_reg;
    
    // Stage 1 logic with handshaking
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            bit_pos_stage1 <= 3'b0;
            valid_stage1 <= 1'b0;
            pattern_stage1 <= 8'b0;
        end else if (trigger) begin
            // Initialize pipeline
            bit_pos_stage1 <= 3'b0;
            valid_stage1 <= 1'b1;
            pattern_stage1 <= pattern;
        end else if (stage1_valid_and_ready) begin
            if (bit_pos_stage1 < 3'b111) begin
                // Increment bit position using carry lookahead adder
                bit_pos_stage1 <= sum;
                pattern_stage1 <= pattern;
            end else begin
                valid_stage1 <= 1'b0;
            end
        end
    end
    
    // Stage 2 logic with handshaking
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            bit_pos_stage2 <= 3'b0;
            valid_stage2 <= 1'b0;
            pattern_stage2 <= 8'b0;
            reset_seq_stage2 <= 8'b0;
        end else if (stage1_valid_and_ready) begin
            // Pass control signals to stage 2
            bit_pos_stage2 <= bit_pos_stage1;
            valid_stage2 <= valid_stage1;
            pattern_stage2 <= pattern_stage1;
            
            // Generate reset sequence based on stage 1 data
            if (trigger) begin
                reset_seq_stage2 <= 8'h0;
            end else begin
                reset_seq_stage2[bit_pos_stage1] <= pattern_stage1[bit_pos_stage1];
            end
        end
    end
    
    // Output stage logic with handshaking
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            reset_seq_reg <= 8'b0;
            out_valid_reg <= 1'b0;
        end else if (stage2_valid_and_ready) begin
            reset_seq_reg <= reset_seq_stage2;
            out_valid_reg <= valid_stage2;
        end else if (in_ready) begin
            // Clear valid flag when data is accepted by downstream module
            out_valid_reg <= 1'b0;
        end
    end
    
endmodule