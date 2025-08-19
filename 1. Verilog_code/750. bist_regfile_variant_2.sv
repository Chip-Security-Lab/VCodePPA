//SystemVerilog
module bist_regfile #(
    parameter DW = 16,
    parameter AW = 4
)(
    input clk,
    input rst_n,
    input start_test,      // 启动自检
    input normal_wr_en,
    input [AW-1:0] addr,
    input [DW-1:0] din,
    output reg [DW-1:0] dout,
    output reg test_done,
    output reg [7:0] error_count,
    output reg bist_active
);
    // BIST状态机定义
    parameter IDLE = 2'b00;
    parameter WRITE_PATTERN = 2'b01;
    parameter READ_VERIFY = 2'b10;
    parameter REPAIR = 2'b11;

    // 存储器定义
    reg [DW-1:0] mem [0:(1<<AW)-1];
    
    // 流水线寄存器
    reg [1:0] state_stage1, state_stage2;
    reg [AW:0] test_addr_stage1, test_addr_stage2;
    reg [DW-1:0] expected_stage1, expected_stage2;
    reg bist_active_stage1, bist_active_stage2;
    reg test_done_stage1, test_done_stage2;
    reg [7:0] error_count_stage1;
    
    // 流水线控制信号
    reg s1_valid, s2_valid;
    reg [AW-1:0] mem_addr_stage1, mem_addr_stage2;
    reg [DW-1:0] mem_wdata_stage1, mem_wdata_stage2;
    reg mem_we_stage1, mem_we_stage2;
    reg [DW-1:0] mem_rdata_stage1;
    reg repair_mode_stage1, repair_mode_stage2;
    
    // March C- 算法模式
    localparam PATTERN0 = 16'hAAAA;
    localparam PATTERN1 = 16'h5555;

    // 第一级流水线：状态控制和地址生成
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state_stage1 <= IDLE;
            test_addr_stage1 <= 0;
            bist_active_stage1 <= 1'b0;
            test_done_stage1 <= 1'b1;
            error_count_stage1 <= 0;
            s1_valid <= 1'b0;
            mem_we_stage1 <= 1'b0;
            mem_addr_stage1 <= 0;
            mem_wdata_stage1 <= 0;
            expected_stage1 <= 0;
            repair_mode_stage1 <= 1'b0;
        end else begin
            s1_valid <= 1'b1;
            
            case(state_stage1)
                IDLE: begin
                    test_done_stage1 <= 1'b1;
                    bist_active_stage1 <= 1'b0;
                    
                    if (normal_wr_en) begin
                        mem_we_stage1 <= 1'b1;
                        mem_addr_stage1 <= addr;
                        mem_wdata_stage1 <= din;
                    end else begin
                        mem_we_stage1 <= 1'b0;
                        mem_addr_stage1 <= addr;
                    end
                    
                    if (start_test) begin
                        state_stage1 <= WRITE_PATTERN;
                        test_addr_stage1 <= 0;
                        test_done_stage1 <= 1'b0;
                        bist_active_stage1 <= 1'b1;
                    end
                end
                
                WRITE_PATTERN: begin
                    mem_we_stage1 <= 1'b1;
                    mem_addr_stage1 <= test_addr_stage1;
                    
                    if (test_addr_stage1[0]) begin
                        mem_wdata_stage1 <= PATTERN1;
                        expected_stage1 <= PATTERN1;
                    end else begin
                        mem_wdata_stage1 <= PATTERN0;
                        expected_stage1 <= PATTERN0;
                    end
                    
                    if (test_addr_stage1 == (1<<AW)-1) begin
                        state_stage1 <= READ_VERIFY;
                        test_addr_stage1 <= 0;
                    end else begin
                        test_addr_stage1 <= test_addr_stage1 + 1;
                    end
                end
                
                READ_VERIFY: begin
                    mem_we_stage1 <= 1'b0;
                    mem_addr_stage1 <= test_addr_stage1;
                    
                    if (test_addr_stage1[0]) begin
                        expected_stage1 <= PATTERN1;
                    end else begin
                        expected_stage1 <= PATTERN0;
                    end
                    
                    if (test_addr_stage1 == (1<<AW)-1) begin
                        state_stage1 <= REPAIR;
                        test_addr_stage1 <= 0;
                    end else begin
                        test_addr_stage1 <= test_addr_stage1 + 1;
                    end
                    repair_mode_stage1 <= 1'b0;
                end
                
                REPAIR: begin
                    mem_we_stage1 <= 1'b1;
                    mem_addr_stage1 <= test_addr_stage1;
                    
                    if (test_addr_stage1[0]) begin
                        mem_wdata_stage1 <= PATTERN1;
                    end else begin
                        mem_wdata_stage1 <= PATTERN0;
                    end
                    
                    repair_mode_stage1 <= 1'b1;
                    
                    if (test_addr_stage1 == (1<<AW)-1) begin
                        state_stage1 <= IDLE;
                    end else begin
                        test_addr_stage1 <= test_addr_stage1 + 1;
                    end
                end
                
                default: state_stage1 <= IDLE;
            endcase
        end
    end

    // 第二级流水线：内存访问和验证
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state_stage2 <= IDLE;
            test_addr_stage2 <= 0;
            expected_stage2 <= 0;
            bist_active_stage2 <= 1'b0;
            test_done_stage2 <= 1'b1;
            s2_valid <= 1'b0;
            mem_we_stage2 <= 1'b0;
            mem_addr_stage2 <= 0;
            mem_wdata_stage2 <= 0;
            mem_rdata_stage1 <= 0;
            repair_mode_stage2 <= 1'b0;
            dout <= 0;
            test_done <= 1'b1;
            bist_active <= 1'b0;
            error_count <= 0;
        end else begin
            // 流水线数据传递
            if (s1_valid) begin
                state_stage2 <= state_stage1;
                test_addr_stage2 <= test_addr_stage1;
                expected_stage2 <= expected_stage1;
                bist_active_stage2 <= bist_active_stage1;
                test_done_stage2 <= test_done_stage1;
                s2_valid <= s1_valid;
                mem_we_stage2 <= mem_we_stage1;
                mem_addr_stage2 <= mem_addr_stage1;
                mem_wdata_stage2 <= mem_wdata_stage1;
                repair_mode_stage2 <= repair_mode_stage1;
                error_count <= error_count_stage1;
            end

            // 内存访问逻辑
            if (mem_we_stage2) begin
                mem[mem_addr_stage2] <= mem_wdata_stage2;
            end
            
            mem_rdata_stage1 <= mem[mem_addr_stage2];
            
            // 输出控制
            if (state_stage2 == IDLE && !bist_active_stage2) begin
                dout <= mem_rdata_stage1;
            end
            
            bist_active <= bist_active_stage2;
            test_done <= test_done_stage2;
            
            // 错误检测和计数
            if (s2_valid && state_stage2 == READ_VERIFY) begin
                if (mem_rdata_stage1 != expected_stage2 && !repair_mode_stage2) begin
                    error_count <= error_count + 1;
                end
            end
        end
    end
endmodule