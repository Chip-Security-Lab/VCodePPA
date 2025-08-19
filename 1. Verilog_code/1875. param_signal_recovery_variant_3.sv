//SystemVerilog
module param_signal_recovery #(
    parameter SIGNAL_WIDTH = 12,
    parameter THRESHOLD = 2048,
    parameter NOISE_MARGIN = 256
)(
    input wire sample_clk,
    input wire rst_n,
    input wire [SIGNAL_WIDTH-1:0] input_signal,
    output reg [SIGNAL_WIDTH-1:0] recovered_signal,
    output reg valid_out
);

    // 计算上下阈值边界
    localparam [SIGNAL_WIDTH-1:0] LOWER_BOUND = THRESHOLD - NOISE_MARGIN;
    localparam [SIGNAL_WIDTH-1:0] UPPER_BOUND = THRESHOLD + NOISE_MARGIN;
    
    // Stage 1: 输入寄存
    reg [SIGNAL_WIDTH-1:0] input_stage1;
    reg valid_stage1;
    
    // Stage 2: 比较计算
    wire [SIGNAL_WIDTH:0] borrow_lower_stage2, borrow_upper_stage2;
    wire [SIGNAL_WIDTH-1:0] diff_lower_stage2, diff_upper_stage2;
    reg valid_stage2;
    
    // Stage 3: 结果判断
    wire valid_signal_stage3;
    reg valid_stage3;
    reg [SIGNAL_WIDTH-1:0] signal_buffer_stage3;
    
    // Stage 1: 输入寄存
    always @(posedge sample_clk or negedge rst_n) begin
        if (!rst_n) begin
            input_stage1 <= 0;
            valid_stage1 <= 0;
        end else begin
            input_stage1 <= input_signal;
            valid_stage1 <= 1'b1;
        end
    end
    
    // Stage 2: 比较计算
    assign borrow_lower_stage2[0] = 1'b0;
    assign borrow_upper_stage2[0] = 1'b0;
    
    genvar i;
    generate
        for (i = 0; i < SIGNAL_WIDTH; i = i + 1) begin : gen_borrow_lower
            assign diff_lower_stage2[i] = input_stage1[i] ^ LOWER_BOUND[i] ^ borrow_lower_stage2[i];
            assign borrow_lower_stage2[i+1] = (~input_stage1[i] & LOWER_BOUND[i]) | 
                                            (~input_stage1[i] & borrow_lower_stage2[i]) | 
                                            (LOWER_BOUND[i] & borrow_lower_stage2[i]);
        end
    endgenerate
    
    generate
        for (i = 0; i < SIGNAL_WIDTH; i = i + 1) begin : gen_borrow_upper
            assign diff_upper_stage2[i] = UPPER_BOUND[i] ^ input_stage1[i] ^ borrow_upper_stage2[i];
            assign borrow_upper_stage2[i+1] = (~UPPER_BOUND[i] & input_stage1[i]) | 
                                            (~UPPER_BOUND[i] & borrow_upper_stage2[i]) | 
                                            (input_stage1[i] & borrow_upper_stage2[i]);
        end
    endgenerate
    
    always @(posedge sample_clk or negedge rst_n) begin
        if (!rst_n) begin
            valid_stage2 <= 0;
        end else begin
            valid_stage2 <= valid_stage1;
        end
    end
    
    // Stage 3: 结果判断
    assign valid_signal_stage3 = ~borrow_lower_stage2[SIGNAL_WIDTH] & ~borrow_upper_stage2[SIGNAL_WIDTH];
    
    always @(posedge sample_clk or negedge rst_n) begin
        if (!rst_n) begin
            valid_stage3 <= 0;
            signal_buffer_stage3 <= 0;
        end else begin
            valid_stage3 <= valid_stage2;
            signal_buffer_stage3 <= input_stage1;
        end
    end
    
    // Stage 4: 输出
    always @(posedge sample_clk or negedge rst_n) begin
        if (!rst_n) begin
            recovered_signal <= 0;
            valid_out <= 0;
        end else begin
            valid_out <= valid_stage3;
            if (valid_signal_stage3)
                recovered_signal <= signal_buffer_stage3;
        end
    end
    
endmodule