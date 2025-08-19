//SystemVerilog
module decoder_fsm_axi (
    // 全局信号
    input wire s_axi_aclk,
    input wire s_axi_aresetn,
    
    // AXI4-Lite 写地址通道
    input wire [31:0] s_axi_awaddr,
    input wire s_axi_awvalid,
    output reg s_axi_awready,
    
    // AXI4-Lite 写数据通道
    input wire [31:0] s_axi_wdata,
    input wire [3:0] s_axi_wstrb,
    input wire s_axi_wvalid,
    output reg s_axi_wready,
    
    // AXI4-Lite 写响应通道
    output reg [1:0] s_axi_bresp,
    output reg s_axi_bvalid,
    input wire s_axi_bready,
    
    // AXI4-Lite 读地址通道
    input wire [31:0] s_axi_araddr,
    input wire s_axi_arvalid,
    output reg s_axi_arready,
    
    // AXI4-Lite 读数据通道
    output reg [31:0] s_axi_rdata,
    output reg [1:0] s_axi_rresp,
    output reg s_axi_rvalid,
    input wire s_axi_rready
);

    // 内部寄存器 - 重定时优化后的流水线
    reg [7:0] decoded_stage2, decoded_final;
    reg [3:0] addr_reg_stage1, addr_reg_stage2;
    wire [7:0] decoded_stage1; // 转为组合逻辑
    wire [3:0] addr_valid_stage1; // 转为组合逻辑
    reg [3:0] addr_valid_stage2;
    
    // FSM 状态定义
    parameter IDLE = 3'b000, DECODE_PREP = 3'b001, DECODE_EXEC = 3'b010, DECODE_FINAL = 3'b011, HOLD = 3'b100;
    reg [2:0] curr_state;
    
    // AXI4-Lite 接口状态
    parameter WAIT_AXI = 2'b00, ADDR_PHASE = 2'b01, DATA_PHASE = 2'b10, RESP_PHASE = 2'b11;
    reg [1:0] write_state, read_state;
    
    // 流水线控制信号 - 重定时优化
    wire decode_valid_stage1; // 转为组合逻辑
    reg decode_valid_stage2;
    
    // 输入寄存器 - 移至组合逻辑后
    wire [3:0] addr_reg;
    assign addr_reg = (read_req_valid) ? s_axi_araddr[3:0] : s_axi_awaddr[3:0];
    
    // AXI4-Lite 写操作处理 - 前向寄存器重定时
    always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
        if (!s_axi_aresetn) begin
            write_state <= WAIT_AXI;
            s_axi_awready <= 1'b0;
            s_axi_wready <= 1'b0;
            s_axi_bvalid <= 1'b0;
            s_axi_bresp <= 2'b00;  // OKAY
        end else begin
            case (write_state)
                WAIT_AXI: begin
                    s_axi_awready <= 1'b1;
                    if (s_axi_awvalid && s_axi_awready) begin
                        // addr_reg 已移至组合逻辑，无需在此赋值
                        s_axi_awready <= 1'b0;
                        s_axi_wready <= 1'b1;
                        write_state <= DATA_PHASE;
                    end
                end
                
                DATA_PHASE: begin
                    if (s_axi_wvalid && s_axi_wready) begin
                        s_axi_wready <= 1'b0;
                        s_axi_bvalid <= 1'b1;
                        s_axi_bresp <= 2'b00;  // OKAY
                        write_state <= RESP_PHASE;
                    end
                end
                
                RESP_PHASE: begin
                    if (s_axi_bready && s_axi_bvalid) begin
                        s_axi_bvalid <= 1'b0;
                        write_state <= WAIT_AXI;
                    end
                end
                
                default: write_state <= WAIT_AXI;
            endcase
        end
    end
    
    // AXI4-Lite 读操作处理 - 前向寄存器重定时
    reg read_req_valid;
    wire [3:0] read_addr_stage1; // 转为组合逻辑
    reg [3:0] read_addr_stage2;
    wire read_data_ready_stage1; // 转为组合逻辑
    reg read_data_ready_stage2, read_data_ready_stage3;
    
    // 组合逻辑 - 前向重定时后的第一级处理
    assign read_addr_stage1 = s_axi_araddr[3:0];
    assign read_data_ready_stage1 = (read_state == DATA_PHASE);
    
    always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
        if (!s_axi_aresetn) begin
            read_state <= WAIT_AXI;
            s_axi_arready <= 1'b0;
            s_axi_rvalid <= 1'b0;
            s_axi_rdata <= 32'h0;
            s_axi_rresp <= 2'b00;  // OKAY
            read_req_valid <= 1'b0;
            read_addr_stage2 <= 4'h0;
            read_data_ready_stage2 <= 1'b0;
            read_data_ready_stage3 <= 1'b0;
        end else begin
            // 流水线移位寄存器 - 传递读请求状态
            read_addr_stage2 <= read_addr_stage1;
            read_data_ready_stage2 <= read_data_ready_stage1;
            read_data_ready_stage3 <= read_data_ready_stage2;
            
            case (read_state)
                WAIT_AXI: begin
                    s_axi_arready <= 1'b1;
                    if (s_axi_arvalid && s_axi_arready) begin
                        // addr_reg 和 read_addr_stage1 已移至组合逻辑
                        read_req_valid <= 1'b1;
                        s_axi_arready <= 1'b0;
                        read_state <= DATA_PHASE;
                    end
                end
                
                DATA_PHASE: begin
                    read_req_valid <= 1'b0;
                    
                    // 等待流水线最终级别完成
                    if (read_data_ready_stage3) begin
                        s_axi_rvalid <= 1'b1;
                        s_axi_rdata <= {24'h0, decoded_final};  // 返回解码后的值
                        s_axi_rresp <= 2'b00;  // OKAY
                        read_state <= RESP_PHASE;
                    end
                end
                
                RESP_PHASE: begin
                    if (s_axi_rready && s_axi_rvalid) begin
                        s_axi_rvalid <= 1'b0;
                        read_state <= WAIT_AXI;
                    end
                end
                
                default: read_state <= WAIT_AXI;
            endcase
        end
    end
    
    // 组合逻辑部分 - 前向寄存器重定时后的第一级解码
    assign decode_valid_stage1 = (curr_state == IDLE && (addr_reg != 0 || read_req_valid));
    assign addr_valid_stage1 = (read_req_valid) ? read_addr_stage1 : addr_reg;
    
    // 第一级解码逻辑 - 转为组合逻辑以实现前向重定时
    assign decoded_stage1 = (addr_valid_stage1 < 4) ? 
                            (8'h01 << addr_valid_stage1[1:0]) :
                            (8'h10 << addr_valid_stage1[1:0]);
    
    // 核心解码器逻辑 - 前向寄存器重定时后的流水线
    always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
        if (!s_axi_aresetn) begin
            curr_state <= IDLE;
            decoded_stage2 <= 8'h00;
            decoded_final <= 8'h00;
            addr_reg_stage1 <= 4'h0;
            addr_reg_stage2 <= 4'h0;
            decode_valid_stage2 <= 1'b0;
            addr_valid_stage2 <= 4'h0;
        end else begin
            // 流水线寄存器传递
            addr_reg_stage1 <= addr_reg;
            addr_reg_stage2 <= addr_reg_stage1;
            
            case(curr_state)
                IDLE: begin
                    if (decode_valid_stage1) begin
                        curr_state <= DECODE_PREP;
                        // decoded_stage1 和 decode_valid_stage1 已移至组合逻辑
                    end
                end
                
                DECODE_PREP: begin
                    curr_state <= DECODE_EXEC;
                    
                    // 寄存前一级组合逻辑的结果
                    addr_valid_stage2 <= {2'b00, addr_valid_stage1[3:2]};
                    decode_valid_stage2 <= decode_valid_stage1;
                end
                
                DECODE_EXEC: begin
                    curr_state <= DECODE_FINAL;
                    
                    // 第二级流水线处理 - 使用组合逻辑结果
                    decoded_stage2 <= decoded_stage1;
                end
                
                DECODE_FINAL: begin
                    curr_state <= HOLD;
                    
                    // 最终流水线级 - 完成解码
                    if (addr_reg_stage2 < 8) begin
                        if (addr_valid_stage2[1:0] == 2'b00)
                            decoded_final <= decoded_stage2;
                        else if (addr_valid_stage2[1:0] == 2'b01)
                            decoded_final <= {decoded_stage2[3:0], 4'h0};
                        else
                            decoded_final <= 8'h00;
                    end else begin
                        decoded_final <= 8'h00;
                    end
                end
                
                HOLD: begin
                    curr_state <= IDLE;
                end
                
                default: curr_state <= IDLE;
            endcase
        end
    end

endmodule