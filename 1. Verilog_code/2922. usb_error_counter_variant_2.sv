//SystemVerilog
module usb_error_counter(
    input wire clk,
    input wire rst_n,
    input wire crc_error,
    input wire pid_error,
    input wire timeout_error,
    input wire bitstuff_error,
    input wire babble_detected,
    input wire clear_counters,
    output reg [7:0] crc_error_count,
    output reg [7:0] pid_error_count,
    output reg [7:0] timeout_error_count,
    output reg [7:0] bitstuff_error_count,
    output reg [7:0] babble_error_count,
    output reg [1:0] error_status
);
    
    localparam NO_ERRORS = 2'b00;
    localparam WARNING = 2'b01;
    localparam CRITICAL = 2'b10;
    
    // ===== 流水线阶段1: 错误信号捕获 =====
    reg crc_error_stage1, pid_error_stage1, timeout_error_stage1;
    reg bitstuff_error_stage1, babble_detected_stage1;
    reg clear_counters_stage1;
    reg [7:0] crc_error_count_stage1, pid_error_count_stage1;
    reg [7:0] timeout_error_count_stage1, bitstuff_error_count_stage1;
    reg [7:0] babble_error_count_stage1;
    reg valid_stage1;

    // ===== 流水线阶段2: 进位生成 =====
    wire crc_at_max_stage1 = (crc_error_count_stage1 == 8'hFF);
    wire pid_at_max_stage1 = (pid_error_count_stage1 == 8'hFF);
    wire timeout_at_max_stage1 = (timeout_error_count_stage1 == 8'hFF);
    wire bitstuff_at_max_stage1 = (bitstuff_error_count_stage1 == 8'hFF);
    wire babble_at_max_stage1 = (babble_error_count_stage1 == 8'hFF);
    
    wire [7:0] increment = 8'd1;
    
    // 先行进位加法器实现 (CRC)
    wire [7:0] crc_gen_stage1, crc_prop_stage1;
    wire [8:0] crc_carry_stage1;
    
    assign crc_gen_stage1 = crc_error_count_stage1 & increment;
    assign crc_prop_stage1 = crc_error_count_stage1 | increment;
    assign crc_carry_stage1[0] = 1'b0;
    
    generate
        genvar i;
        for (i = 0; i < 8; i = i + 1) begin : crc_cla_gen
            assign crc_carry_stage1[i+1] = crc_gen_stage1[i] | (crc_prop_stage1[i] & crc_carry_stage1[i]);
        end
    endgenerate
    
    wire [7:0] crc_next_stage1 = crc_error_count_stage1 ^ increment ^ {crc_carry_stage1[7:0], 1'b0};
    
    // 先行进位加法器实现 (PID)
    wire [7:0] pid_gen_stage1, pid_prop_stage1;
    wire [8:0] pid_carry_stage1;
    
    assign pid_gen_stage1 = pid_error_count_stage1 & increment;
    assign pid_prop_stage1 = pid_error_count_stage1 | increment;
    assign pid_carry_stage1[0] = 1'b0;
    
    generate
        genvar j;
        for (j = 0; j < 8; j = j + 1) begin : pid_cla_gen
            assign pid_carry_stage1[j+1] = pid_gen_stage1[j] | (pid_prop_stage1[j] & pid_carry_stage1[j]);
        end
    endgenerate
    
    wire [7:0] pid_next_stage1 = pid_error_count_stage1 ^ increment ^ {pid_carry_stage1[7:0], 1'b0};
    
    // 先行进位加法器实现 (Timeout)
    wire [7:0] timeout_gen_stage1, timeout_prop_stage1;
    wire [8:0] timeout_carry_stage1;
    
    assign timeout_gen_stage1 = timeout_error_count_stage1 & increment;
    assign timeout_prop_stage1 = timeout_error_count_stage1 | increment;
    assign timeout_carry_stage1[0] = 1'b0;
    
    generate
        genvar k;
        for (k = 0; k < 8; k = k + 1) begin : timeout_cla_gen
            assign timeout_carry_stage1[k+1] = timeout_gen_stage1[k] | (timeout_prop_stage1[k] & timeout_carry_stage1[k]);
        end
    endgenerate
    
    wire [7:0] timeout_next_stage1 = timeout_error_count_stage1 ^ increment ^ {timeout_carry_stage1[7:0], 1'b0};
    
    // 先行进位加法器实现 (Bitstuff)
    wire [7:0] bitstuff_gen_stage1, bitstuff_prop_stage1;
    wire [8:0] bitstuff_carry_stage1;
    
    assign bitstuff_gen_stage1 = bitstuff_error_count_stage1 & increment;
    assign bitstuff_prop_stage1 = bitstuff_error_count_stage1 | increment;
    assign bitstuff_carry_stage1[0] = 1'b0;
    
    generate
        genvar l;
        for (l = 0; l < 8; l = l + 1) begin : bitstuff_cla_gen
            assign bitstuff_carry_stage1[l+1] = bitstuff_gen_stage1[l] | (bitstuff_prop_stage1[l] & bitstuff_carry_stage1[l]);
        end
    endgenerate
    
    wire [7:0] bitstuff_next_stage1 = bitstuff_error_count_stage1 ^ increment ^ {bitstuff_carry_stage1[7:0], 1'b0};
    
    // 先行进位加法器实现 (Babble)
    wire [7:0] babble_gen_stage1, babble_prop_stage1;
    wire [8:0] babble_carry_stage1;
    
    assign babble_gen_stage1 = babble_error_count_stage1 & increment;
    assign babble_prop_stage1 = babble_error_count_stage1 | increment;
    assign babble_carry_stage1[0] = 1'b0;
    
    generate
        genvar m;
        for (m = 0; m < 8; m = m + 1) begin : babble_cla_gen
            assign babble_carry_stage1[m+1] = babble_gen_stage1[m] | (babble_prop_stage1[m] & babble_carry_stage1[m]);
        end
    endgenerate
    
    wire [7:0] babble_next_stage1 = babble_error_count_stage1 ^ increment ^ {babble_carry_stage1[7:0], 1'b0};

    // 流水线阶段2的寄存器
    reg [7:0] crc_next_stage2, pid_next_stage2, timeout_next_stage2;
    reg [7:0] bitstuff_next_stage2, babble_next_stage2;
    reg crc_error_stage2, pid_error_stage2, timeout_error_stage2;
    reg bitstuff_error_stage2, babble_detected_stage2;
    reg clear_counters_stage2;
    reg crc_at_max_stage2, pid_at_max_stage2, timeout_at_max_stage2;
    reg bitstuff_at_max_stage2, babble_at_max_stage2;
    reg [7:0] crc_error_count_stage2, pid_error_count_stage2;
    reg [7:0] timeout_error_count_stage2, bitstuff_error_count_stage2;
    reg [7:0] babble_error_count_stage2;
    reg valid_stage2;

    // ===== 流水线阶段3: 错误状态判断 =====
    wire babble_critical_stage2 = (babble_error_count_stage2 >= 8'd3);
    wire timeout_critical_stage2 = (timeout_error_count_stage2 >= 8'd10);
    wire is_critical_stage2 = babble_critical_stage2 || timeout_critical_stage2;
    
    wire any_error_stage2 = crc_error_stage2 | pid_error_stage2 | 
                           timeout_error_stage2 | bitstuff_error_stage2 | 
                           babble_detected_stage2;
    
    // 流水线控制信号
    wire flush = clear_counters_stage1 | clear_counters_stage2;
    
    // 流水线阶段1: 错误信号捕获
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            crc_error_stage1 <= 1'b0;
            pid_error_stage1 <= 1'b0;
            timeout_error_stage1 <= 1'b0;
            bitstuff_error_stage1 <= 1'b0;
            babble_detected_stage1 <= 1'b0;
            clear_counters_stage1 <= 1'b0;
            crc_error_count_stage1 <= 8'd0;
            pid_error_count_stage1 <= 8'd0;
            timeout_error_count_stage1 <= 8'd0;
            bitstuff_error_count_stage1 <= 8'd0;
            babble_error_count_stage1 <= 8'd0;
            valid_stage1 <= 1'b0;
        end
        else begin
            crc_error_stage1 <= crc_error;
            pid_error_stage1 <= pid_error;
            timeout_error_stage1 <= timeout_error;
            bitstuff_error_stage1 <= bitstuff_error;
            babble_detected_stage1 <= babble_detected;
            clear_counters_stage1 <= clear_counters;
            crc_error_count_stage1 <= crc_error_count;
            pid_error_count_stage1 <= pid_error_count;
            timeout_error_count_stage1 <= timeout_error_count;
            bitstuff_error_count_stage1 <= bitstuff_error_count;
            babble_error_count_stage1 <= babble_error_count;
            valid_stage1 <= 1'b1;
        end
    end
    
    // 流水线阶段2: 进位计算
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            crc_next_stage2 <= 8'd0;
            pid_next_stage2 <= 8'd0;
            timeout_next_stage2 <= 8'd0;
            bitstuff_next_stage2 <= 8'd0;
            babble_next_stage2 <= 8'd0;
            crc_error_stage2 <= 1'b0;
            pid_error_stage2 <= 1'b0;
            timeout_error_stage2 <= 1'b0;
            bitstuff_error_stage2 <= 1'b0;
            babble_detected_stage2 <= 1'b0;
            clear_counters_stage2 <= 1'b0;
            crc_at_max_stage2 <= 1'b0;
            pid_at_max_stage2 <= 1'b0;
            timeout_at_max_stage2 <= 1'b0;
            bitstuff_at_max_stage2 <= 1'b0;
            babble_at_max_stage2 <= 1'b0;
            crc_error_count_stage2 <= 8'd0;
            pid_error_count_stage2 <= 8'd0;
            timeout_error_count_stage2 <= 8'd0;
            bitstuff_error_count_stage2 <= 8'd0;
            babble_error_count_stage2 <= 8'd0;
            valid_stage2 <= 1'b0;
        end
        else if (valid_stage1) begin
            crc_next_stage2 <= crc_next_stage1;
            pid_next_stage2 <= pid_next_stage1;
            timeout_next_stage2 <= timeout_next_stage1;
            bitstuff_next_stage2 <= bitstuff_next_stage1;
            babble_next_stage2 <= babble_next_stage1;
            crc_error_stage2 <= crc_error_stage1;
            pid_error_stage2 <= pid_error_stage1;
            timeout_error_stage2 <= timeout_error_stage1;
            bitstuff_error_stage2 <= bitstuff_error_stage1;
            babble_detected_stage2 <= babble_detected_stage1;
            clear_counters_stage2 <= clear_counters_stage1;
            crc_at_max_stage2 <= crc_at_max_stage1;
            pid_at_max_stage2 <= pid_at_max_stage1;
            timeout_at_max_stage2 <= timeout_at_max_stage1;
            bitstuff_at_max_stage2 <= bitstuff_at_max_stage1;
            babble_at_max_stage2 <= babble_at_max_stage1;
            crc_error_count_stage2 <= crc_error_count_stage1;
            pid_error_count_stage2 <= pid_error_count_stage1;
            timeout_error_count_stage2 <= timeout_error_count_stage1;
            bitstuff_error_count_stage2 <= bitstuff_error_count_stage1;
            babble_error_count_stage2 <= babble_error_count_stage1;
            valid_stage2 <= valid_stage1;
        end
    end
    
    // 流水线阶段3: 错误状态输出和计数器更新
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // 复位状态
            crc_error_count <= 8'd0;
            pid_error_count <= 8'd0;
            timeout_error_count <= 8'd0;
            bitstuff_error_count <= 8'd0;
            babble_error_count <= 8'd0;
            error_status <= NO_ERRORS;
        end 
        else if (clear_counters | clear_counters_stage1 | clear_counters_stage2) begin
            // 清除计数器 - 任何阶段的清除信号都立即生效
            crc_error_count <= 8'd0;
            pid_error_count <= 8'd0;
            timeout_error_count <= 8'd0;
            bitstuff_error_count <= 8'd0;
            babble_error_count <= 8'd0;
            error_status <= NO_ERRORS;
        end 
        else if (valid_stage2) begin
            // 错误计数更新 - 使用流水线中的计算结果
            if (crc_error_stage2 && !crc_at_max_stage2)
                crc_error_count <= crc_next_stage2;
                
            if (pid_error_stage2 && !pid_at_max_stage2)
                pid_error_count <= pid_next_stage2;
                
            if (timeout_error_stage2 && !timeout_at_max_stage2)
                timeout_error_count <= timeout_next_stage2;
                
            if (bitstuff_error_stage2 && !bitstuff_at_max_stage2)
                bitstuff_error_count <= bitstuff_next_stage2;
                
            if (babble_detected_stage2 && !babble_at_max_stage2)
                babble_error_count <= babble_next_stage2;
            
            // 优化错误状态更新逻辑
            error_status <= is_critical_stage2 ? CRITICAL : 
                           any_error_stage2    ? WARNING  : 
                                               NO_ERRORS;
        end
    end
endmodule