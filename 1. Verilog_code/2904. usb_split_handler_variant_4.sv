//SystemVerilog
//IEEE 1364-2005 SystemVerilog
module usb_split_handler(
    input wire clk,
    input wire reset,
    
    // AXI4-Lite Slave Interface
    // Write Address Channel
    input wire [7:0] s_axil_awaddr,
    input wire [2:0] s_axil_awprot,
    input wire s_axil_awvalid,
    output reg s_axil_awready,
    
    // Write Data Channel
    input wire [31:0] s_axil_wdata,
    input wire [3:0] s_axil_wstrb,
    input wire s_axil_wvalid,
    output reg s_axil_wready,
    
    // Write Response Channel
    output reg [1:0] s_axil_bresp,
    output reg s_axil_bvalid,
    input wire s_axil_bready,
    
    // Read Address Channel
    input wire [7:0] s_axil_araddr,
    input wire [2:0] s_axil_arprot,
    input wire s_axil_arvalid,
    output reg s_axil_arready,
    
    // Read Data Channel
    output reg [31:0] s_axil_rdata,
    output reg [1:0] s_axil_rresp,
    output reg s_axil_rvalid,
    input wire s_axil_rready
);

    // 状态定义
    localparam IDLE = 2'b00, START = 2'b01, WAIT = 2'b10, COMPLETE = 2'b11;
    
    // 内部寄存器
    reg [3:0] hub_addr;
    reg [3:0] port_num;
    reg [7:0] transaction_type;
    reg start_split;
    reg complete_split;
    reg [15:0] split_token;
    reg token_valid;
    reg [1:0] state;
    
    // AXI4-Lite 寄存器地址映射
    localparam ADDR_CTRL      = 8'h00;   // 控制寄存器 [start_split, complete_split]
    localparam ADDR_HUB_PORT  = 8'h04;   // hub_addr(31:28), port_num(27:24)
    localparam ADDR_TRANS     = 8'h08;   // transaction_type
    localparam ADDR_STATUS    = 8'h0C;   // 状态寄存器 [token_valid, state]
    localparam ADDR_TOKEN     = 8'h10;   // split_token
    
    // 流水线寄存器
    reg [3:0] hub_addr_stage1, hub_addr_stage2;
    reg [3:0] port_num_stage1, port_num_stage2;
    reg [7:0] transaction_type_stage1, transaction_type_stage2;
    reg start_split_stage1, start_split_stage2;
    reg complete_split_stage1, complete_split_stage2;
    
    // 中间处理寄存器
    reg [7:0] command_byte_stage1, command_byte_stage2, command_byte_stage3;
    reg [15:0] token_pre_stage1, token_pre_stage2, token_pre_stage3;
    reg token_valid_pre_stage1, token_valid_pre_stage2, token_valid_pre_stage3;
    reg [1:0] next_state_stage1, next_state_stage2, next_state_stage3;

    // AXI4-Lite 写地址通道处理
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            s_axil_awready <= 1'b0;
        end else begin
            if (~s_axil_awready && s_axil_awvalid) begin
                s_axil_awready <= 1'b1;
            end else begin
                s_axil_awready <= 1'b0;
            end
        end
    end

    // AXI4-Lite 写数据通道处理
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            s_axil_wready <= 1'b0;
            start_split <= 1'b0;
            complete_split <= 1'b0;
            hub_addr <= 4'b0000;
            port_num <= 4'b0000;
            transaction_type <= 8'h00;
        end else begin
            if (~s_axil_wready && s_axil_wvalid && s_axil_awvalid) begin
                s_axil_wready <= 1'b1;
                
                case (s_axil_awaddr)
                    ADDR_CTRL: begin
                        if (s_axil_wstrb[0]) begin
                            start_split <= s_axil_wdata[0];
                            complete_split <= s_axil_wdata[1];
                        end
                    end
                    ADDR_HUB_PORT: begin
                        if (s_axil_wstrb[3]) begin
                            hub_addr <= s_axil_wdata[31:28];
                            port_num <= s_axil_wdata[27:24];
                        end
                    end
                    ADDR_TRANS: begin
                        if (s_axil_wstrb[0]) begin
                            transaction_type <= s_axil_wdata[7:0];
                        end
                    end
                    default: begin
                        // 其他地址不可写
                    end
                endcase
            end else begin
                s_axil_wready <= 1'b0;
                // 状态机处理后自动清除控制位
                if (state != IDLE) begin
                    start_split <= 1'b0;
                end
                if (state == COMPLETE) begin
                    complete_split <= 1'b0;
                end
            end
        end
    end

    // AXI4-Lite 写响应通道处理
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            s_axil_bvalid <= 1'b0;
            s_axil_bresp <= 2'b00;
        end else begin
            if (~s_axil_bvalid && s_axil_wready && s_axil_wvalid) begin
                s_axil_bvalid <= 1'b1;
                s_axil_bresp <= 2'b00;  // OKAY
            end else if (s_axil_bvalid && s_axil_bready) begin
                s_axil_bvalid <= 1'b0;
            end
        end
    end

    // AXI4-Lite 读地址通道处理
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            s_axil_arready <= 1'b0;
        end else begin
            if (~s_axil_arready && s_axil_arvalid) begin
                s_axil_arready <= 1'b1;
            end else begin
                s_axil_arready <= 1'b0;
            end
        end
    end

    // AXI4-Lite 读数据通道处理
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            s_axil_rvalid <= 1'b0;
            s_axil_rresp <= 2'b00;
            s_axil_rdata <= 32'h00000000;
        end else begin
            if (s_axil_arready && s_axil_arvalid && ~s_axil_rvalid) begin
                s_axil_rvalid <= 1'b1;
                s_axil_rresp <= 2'b00;  // OKAY
                
                case (s_axil_araddr)
                    ADDR_CTRL: begin
                        s_axil_rdata <= {30'h0, complete_split, start_split};
                    end
                    ADDR_HUB_PORT: begin
                        s_axil_rdata <= {hub_addr, port_num, 24'h0};
                    end
                    ADDR_TRANS: begin
                        s_axil_rdata <= {24'h0, transaction_type};
                    end
                    ADDR_STATUS: begin
                        s_axil_rdata <= {29'h0, token_valid, state};
                    end
                    ADDR_TOKEN: begin
                        s_axil_rdata <= {16'h0, split_token};
                    end
                    default: begin
                        s_axil_rdata <= 32'h00000000;
                    end
                endcase
            end else if (s_axil_rvalid && s_axil_rready) begin
                s_axil_rvalid <= 1'b0;
            end
        end
    end

    // 流水线阶段1：输入注册和初步处理
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            hub_addr_stage1 <= 4'b0000;
            port_num_stage1 <= 4'b0000;
            transaction_type_stage1 <= 8'h00;
            start_split_stage1 <= 1'b0;
            complete_split_stage1 <= 1'b0;
            
            command_byte_stage1 <= 8'h00;
            token_pre_stage1 <= 16'h0000;
            token_valid_pre_stage1 <= 1'b0;
            next_state_stage1 <= IDLE;
        end else begin
            // 注册输入信号
            hub_addr_stage1 <= hub_addr;
            port_num_stage1 <= port_num;
            transaction_type_stage1 <= transaction_type;
            start_split_stage1 <= start_split;
            complete_split_stage1 <= complete_split;
            
            // 初步状态转换逻辑
            case (state)
                IDLE: begin
                    if (start_split) begin
                        command_byte_stage1 <= {transaction_type[1:0], 2'b00, port_num};
                        token_pre_stage1 <= {hub_addr, {transaction_type[1:0], 2'b00, port_num}, 4'b0000};
                        token_valid_pre_stage1 <= 1'b1;
                        next_state_stage1 <= START;
                    end else if (complete_split) begin
                        command_byte_stage1 <= {transaction_type[1:0], 2'b10, port_num};
                        token_pre_stage1 <= {hub_addr, {transaction_type[1:0], 2'b10, port_num}, 4'b0000};
                        token_valid_pre_stage1 <= 1'b1;
                        next_state_stage1 <= COMPLETE;
                    end else begin
                        command_byte_stage1 <= 8'h00;
                        token_pre_stage1 <= 16'h0000;
                        token_valid_pre_stage1 <= 1'b0;
                        next_state_stage1 <= state;
                    end
                end
                START: begin
                    command_byte_stage1 <= 8'h00;
                    token_pre_stage1 <= 16'h0000;
                    token_valid_pre_stage1 <= 1'b0;
                    next_state_stage1 <= WAIT;
                end
                WAIT: begin
                    if (complete_split) begin
                        command_byte_stage1 <= {transaction_type[1:0], 2'b10, port_num};
                        token_pre_stage1 <= {hub_addr, {transaction_type[1:0], 2'b10, port_num}, 4'b0000};
                        token_valid_pre_stage1 <= 1'b1;
                        next_state_stage1 <= COMPLETE;
                    end else begin
                        command_byte_stage1 <= 8'h00;
                        token_pre_stage1 <= 16'h0000;
                        token_valid_pre_stage1 <= 1'b0;
                        next_state_stage1 <= state;
                    end
                end
                COMPLETE: begin
                    command_byte_stage1 <= 8'h00;
                    token_pre_stage1 <= 16'h0000;
                    token_valid_pre_stage1 <= 1'b0;
                    next_state_stage1 <= IDLE;
                end
                default: begin
                    command_byte_stage1 <= 8'h00;
                    token_pre_stage1 <= 16'h0000;
                    token_valid_pre_stage1 <= 1'b0;
                    next_state_stage1 <= IDLE;
                end
            endcase
        end
    end
    
    // 流水线阶段2：中间处理和命令计算
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            hub_addr_stage2 <= 4'b0000;
            port_num_stage2 <= 4'b0000;
            transaction_type_stage2 <= 8'h00;
            start_split_stage2 <= 1'b0;
            complete_split_stage2 <= 1'b0;
            
            command_byte_stage2 <= 8'h00;
            token_pre_stage2 <= 16'h0000;
            token_valid_pre_stage2 <= 1'b0;
            next_state_stage2 <= IDLE;
        end else begin
            // 传递流水线信号
            hub_addr_stage2 <= hub_addr_stage1;
            port_num_stage2 <= port_num_stage1;
            transaction_type_stage2 <= transaction_type_stage1;
            start_split_stage2 <= start_split_stage1;
            complete_split_stage2 <= complete_split_stage1;
            
            // 处理命令和状态
            command_byte_stage2 <= command_byte_stage1;
            token_pre_stage2 <= token_pre_stage1;
            token_valid_pre_stage2 <= token_valid_pre_stage1;
            next_state_stage2 <= next_state_stage1;
        end
    end
    
    // 流水线阶段3：最终输出处理
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            command_byte_stage3 <= 8'h00;
            token_pre_stage3 <= 16'h0000;
            token_valid_pre_stage3 <= 1'b0;
            next_state_stage3 <= IDLE;
        end else begin
            // 最终处理和验证
            command_byte_stage3 <= command_byte_stage2;
            token_pre_stage3 <= token_pre_stage2;
            token_valid_pre_stage3 <= token_valid_pre_stage2;
            next_state_stage3 <= next_state_stage2;
        end
    end
    
    // 输出寄存器更新
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= IDLE;
            token_valid <= 1'b0;
            split_token <= 16'h0000;
        end else begin
            state <= next_state_stage3;
            token_valid <= token_valid_pre_stage3;
            split_token <= token_pre_stage3;
        end
    end
endmodule