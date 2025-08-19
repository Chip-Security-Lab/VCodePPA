//SystemVerilog - IEEE 1364-2005
module biphase_mark_codec_axi (
    input wire s_axi_aclk,
    input wire s_axi_aresetn,
    
    // AXI4-Lite写地址通道
    input wire [31:0] s_axi_awaddr,
    input wire s_axi_awvalid,
    output reg s_axi_awready,
    
    // AXI4-Lite写数据通道
    input wire [31:0] s_axi_wdata,
    input wire [3:0] s_axi_wstrb,
    input wire s_axi_wvalid,
    output reg s_axi_wready,
    
    // AXI4-Lite写响应通道
    output reg [1:0] s_axi_bresp,
    output reg s_axi_bvalid,
    input wire s_axi_bready,
    
    // AXI4-Lite读地址通道
    input wire [31:0] s_axi_araddr,
    input wire s_axi_arvalid,
    output reg s_axi_arready,
    
    // AXI4-Lite读数据通道
    output reg [31:0] s_axi_rdata,
    output reg [1:0] s_axi_rresp,
    output reg s_axi_rvalid,
    input wire s_axi_rready,
    
    // Biphase接口信号
    input wire biphase_in,
    output reg biphase_out,
    output reg data_out,
    output reg data_valid
);

    // 内部寄存器定义
    reg [31:0] control_reg;    // 控制寄存器 [0]=encode, [1]=decode, [2]=data_in
    reg [31:0] status_reg;     // 状态寄存器 [0]=biphase_out, [1]=data_out, [2]=data_valid
    
    // 内部信号
    wire encode, decode, data_in;
    
    // 流水线寄存器
    reg last_bit_stage1, last_bit_stage2, last_bit_stage3;
    reg [1:0] bit_timer_stage1, bit_timer_stage2, bit_timer_stage3;
    reg biphase_out_stage1, biphase_out_stage2;
    reg data_out_stage1, data_out_stage2;
    reg data_valid_stage1, data_valid_stage2;
    
    // 控制信号流水线
    reg encode_stage1, encode_stage2, encode_stage3;
    reg decode_stage1, decode_stage2, decode_stage3;
    reg data_in_stage1, data_in_stage2, data_in_stage3;
    
    // 寄存器地址映射
    localparam ADDR_CONTROL = 4'h0;
    localparam ADDR_STATUS = 4'h4;
    
    // 从控制寄存器中提取控制信号
    assign encode = control_reg[0];
    assign decode = control_reg[1];
    assign data_in = control_reg[2];
    
    // 控制信号流水线级联
    always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
        if (!s_axi_aresetn) begin
            encode_stage1 <= 1'b0;
            encode_stage2 <= 1'b0;
            encode_stage3 <= 1'b0;
            decode_stage1 <= 1'b0;
            decode_stage2 <= 1'b0;
            decode_stage3 <= 1'b0;
            data_in_stage1 <= 1'b0;
            data_in_stage2 <= 1'b0;
            data_in_stage3 <= 1'b0;
        end else begin
            // 第一级
            encode_stage1 <= encode;
            decode_stage1 <= decode;
            data_in_stage1 <= data_in;
            
            // 第二级
            encode_stage2 <= encode_stage1;
            decode_stage2 <= decode_stage1;
            data_in_stage2 <= data_in_stage1;
            
            // 第三级
            encode_stage3 <= encode_stage2;
            decode_stage3 <= decode_stage2;
            data_in_stage3 <= data_in_stage2;
        end
    end
    
    // 向状态寄存器更新状态 - 增加流水线级数
    always @(posedge s_axi_aclk) begin
        status_reg[0] <= biphase_out;
        status_reg[1] <= data_out;
        status_reg[2] <= data_valid;
    end
    
    // AXI4-Lite写地址通道处理 - 流水线化
    reg [3:0] write_addr_stage1, write_addr_stage2;
    reg write_addr_valid_stage1, write_addr_valid_stage2;
    reg s_axi_awready_next;
    
    always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
        if (!s_axi_aresetn) begin
            s_axi_awready <= 1'b0;
            s_axi_awready_next <= 1'b0;
            write_addr_stage1 <= 4'h0;
            write_addr_stage2 <= 4'h0;
            write_addr_valid_stage1 <= 1'b0;
            write_addr_valid_stage2 <= 1'b0;
        end else begin
            // 第一级流水线
            s_axi_awready <= s_axi_awready_next;
            
            if (s_axi_awvalid && !s_axi_awready && !write_addr_valid_stage1) begin
                s_axi_awready_next <= 1'b1;
                write_addr_stage1 <= s_axi_awaddr[5:2];
                write_addr_valid_stage1 <= 1'b1;
            end else begin
                s_axi_awready_next <= 1'b0;
                if (s_axi_wvalid && s_axi_wready)
                    write_addr_valid_stage1 <= 1'b0;
            end
            
            // 第二级流水线
            write_addr_stage2 <= write_addr_stage1;
            write_addr_valid_stage2 <= write_addr_valid_stage1;
        end
    end
    
    // AXI4-Lite写数据通道处理 - 流水线化
    reg s_axi_wready_next;
    reg [31:0] control_reg_next;
    
    always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
        if (!s_axi_aresetn) begin
            s_axi_wready <= 1'b0;
            s_axi_wready_next <= 1'b0;
            control_reg <= 32'h0;
            control_reg_next <= 32'h0;
        end else begin
            // 第一级流水线
            s_axi_wready <= s_axi_wready_next;
            control_reg <= control_reg_next;
            
            if (s_axi_wvalid && !s_axi_wready && write_addr_valid_stage2) begin
                s_axi_wready_next <= 1'b1;
                
                if (write_addr_stage2 == ADDR_CONTROL) begin
                    control_reg_next = control_reg;
                    if (s_axi_wstrb[0]) control_reg_next[7:0] = s_axi_wdata[7:0];
                    if (s_axi_wstrb[1]) control_reg_next[15:8] = s_axi_wdata[15:8];
                    if (s_axi_wstrb[2]) control_reg_next[23:16] = s_axi_wdata[23:16];
                    if (s_axi_wstrb[3]) control_reg_next[31:24] = s_axi_wdata[31:24];
                end else begin
                    control_reg_next = control_reg;
                end
            end else begin
                s_axi_wready_next <= 1'b0;
                control_reg_next = control_reg;
            end
        end
    end
    
    // AXI4-Lite写响应通道处理 - 流水线化
    reg s_axi_bvalid_stage1, s_axi_bvalid_next;
    reg [1:0] s_axi_bresp_stage1, s_axi_bresp_next;
    
    always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
        if (!s_axi_aresetn) begin
            s_axi_bvalid <= 1'b0;
            s_axi_bvalid_stage1 <= 1'b0;
            s_axi_bvalid_next <= 1'b0;
            s_axi_bresp <= 2'b00;
            s_axi_bresp_stage1 <= 2'b00;
            s_axi_bresp_next <= 2'b00;
        end else begin
            // 第一级流水线
            s_axi_bvalid_stage1 <= s_axi_bvalid_next;
            s_axi_bresp_stage1 <= s_axi_bresp_next;
            
            // 第二级流水线
            s_axi_bvalid <= s_axi_bvalid_stage1;
            s_axi_bresp <= s_axi_bresp_stage1;
            
            if (s_axi_wvalid && s_axi_wready) begin
                s_axi_bvalid_next <= 1'b1;
                s_axi_bresp_next <= 2'b00; // OKAY 响应
            end else if (s_axi_bvalid && s_axi_bready) begin
                s_axi_bvalid_next <= 1'b0;
            end else begin
                s_axi_bvalid_next <= s_axi_bvalid_stage1;
                s_axi_bresp_next <= s_axi_bresp_stage1;
            end
        end
    end
    
    // AXI4-Lite读地址通道处理 - 流水线化
    reg [3:0] read_addr_stage1, read_addr_stage2;
    reg read_addr_valid_stage1, read_addr_valid_stage2;
    reg s_axi_arready_next;
    
    always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
        if (!s_axi_aresetn) begin
            s_axi_arready <= 1'b0;
            s_axi_arready_next <= 1'b0;
            read_addr_stage1 <= 4'h0;
            read_addr_stage2 <= 4'h0;
            read_addr_valid_stage1 <= 1'b0;
            read_addr_valid_stage2 <= 1'b0;
        end else begin
            // 第一级流水线
            s_axi_arready <= s_axi_arready_next;
            
            if (s_axi_arvalid && !s_axi_arready && !read_addr_valid_stage1) begin
                s_axi_arready_next <= 1'b1;
                read_addr_stage1 <= s_axi_araddr[5:2];
                read_addr_valid_stage1 <= 1'b1;
            end else begin
                s_axi_arready_next <= 1'b0;
                if (s_axi_rvalid && s_axi_rready)
                    read_addr_valid_stage1 <= 1'b0;
            end
            
            // 第二级流水线
            read_addr_stage2 <= read_addr_stage1;
            read_addr_valid_stage2 <= read_addr_valid_stage1;
        end
    end
    
    // AXI4-Lite读数据通道处理 - 流水线化
    reg s_axi_rvalid_stage1, s_axi_rvalid_next;
    reg [31:0] s_axi_rdata_stage1, s_axi_rdata_next;
    reg [1:0] s_axi_rresp_stage1, s_axi_rresp_next;
    
    always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
        if (!s_axi_aresetn) begin
            s_axi_rvalid <= 1'b0;
            s_axi_rvalid_stage1 <= 1'b0;
            s_axi_rvalid_next <= 1'b0;
            s_axi_rdata <= 32'h0;
            s_axi_rdata_stage1 <= 32'h0;
            s_axi_rdata_next <= 32'h0;
            s_axi_rresp <= 2'b00;
            s_axi_rresp_stage1 <= 2'b00;
            s_axi_rresp_next <= 2'b00;
        end else begin
            // 第一级流水线
            s_axi_rvalid_stage1 <= s_axi_rvalid_next;
            s_axi_rdata_stage1 <= s_axi_rdata_next;
            s_axi_rresp_stage1 <= s_axi_rresp_next;
            
            // 第二级流水线
            s_axi_rvalid <= s_axi_rvalid_stage1;
            s_axi_rdata <= s_axi_rdata_stage1;
            s_axi_rresp <= s_axi_rresp_stage1;
            
            if (read_addr_valid_stage2 && !s_axi_rvalid_stage1) begin
                s_axi_rvalid_next <= 1'b1;
                s_axi_rresp_next <= 2'b00; // OKAY 响应
                
                if (read_addr_stage2 == ADDR_CONTROL) begin
                    s_axi_rdata_next <= control_reg;
                end else if (read_addr_stage2 == ADDR_STATUS) begin
                    s_axi_rdata_next <= status_reg;
                end else begin
                    s_axi_rdata_next <= 32'h0;
                end
            end else if (s_axi_rvalid && s_axi_rready) begin
                s_axi_rvalid_next <= 1'b0;
            end else begin
                s_axi_rvalid_next <= s_axi_rvalid_stage1;
                s_axi_rdata_next <= s_axi_rdata_stage1;
                s_axi_rresp_next <= s_axi_rresp_stage1;
            end
        end
    end
    
    // Bi-phase mark编码部分 - 增加流水线级数
    reg [1:0] bit_timer_next;
    reg biphase_out_next;
    reg transition_detected;
    reg transition_detected_stage1, transition_detected_stage2;
    
    always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
        if (!s_axi_aresetn) begin
            // 复位所有流水线级数的寄存器
            bit_timer_stage1 <= 2'b00;
            bit_timer_stage2 <= 2'b00;
            bit_timer_stage3 <= 2'b00;
            bit_timer_next <= 2'b00;
            
            biphase_out <= 1'b0;
            biphase_out_stage1 <= 1'b0;
            biphase_out_stage2 <= 1'b0;
            biphase_out_next <= 1'b0;
            
            last_bit_stage1 <= 1'b0;
            last_bit_stage2 <= 1'b0;
            last_bit_stage3 <= 1'b0;
            
            data_out <= 1'b0;
            data_out_stage1 <= 1'b0;
            data_out_stage2 <= 1'b0;
            
            data_valid <= 1'b0;
            data_valid_stage1 <= 1'b0;
            data_valid_stage2 <= 1'b0;
            
            transition_detected <= 1'b0;
            transition_detected_stage1 <= 1'b0;
            transition_detected_stage2 <= 1'b0;
        end else begin
            // 第一级流水线 - 计时器和转换检测
            bit_timer_stage1 <= bit_timer_next;
            
            if (encode_stage1) begin
                bit_timer_next <= bit_timer_stage1 + 1'b1;
                
                // 检测何时需要信号转换
                if (bit_timer_stage1 == 2'b00) begin
                    transition_detected <= 1'b1; // 位时间开始总是转换
                end else if (bit_timer_stage1 == 2'b10 && data_in_stage1) begin
                    transition_detected <= 1'b1; // 位中间且数据为'1'时额外转换
                end else begin
                    transition_detected <= 1'b0;
                end
            end else begin
                bit_timer_next <= 2'b00;
                transition_detected <= 1'b0;
            end
            
            // 第二级流水线 - 转换检测传播
            bit_timer_stage2 <= bit_timer_stage1;
            transition_detected_stage1 <= transition_detected;
            biphase_out_stage1 <= biphase_out;
            data_out_stage1 <= data_out;
            data_valid_stage1 <= data_valid;
            
            // 第三级流水线 - 实际信号转换
            bit_timer_stage3 <= bit_timer_stage2;
            transition_detected_stage2 <= transition_detected_stage1;
            biphase_out_stage2 <= biphase_out_stage1;
            data_out_stage2 <= data_out_stage1;
            data_valid_stage2 <= data_valid_stage1;
            
            // 最终输出级 - 执行信号转换
            if (encode_stage3) begin
                if (transition_detected_stage2) begin
                    biphase_out <= ~biphase_out_stage2; // 执行信号转换
                end else begin
                    biphase_out <= biphase_out_stage2;
                end
            end
            
            // 数据输出和有效性信号
            data_out <= data_out_stage2;
            data_valid <= data_valid_stage2;
        end
    end
    
    // Bi-phase mark解码逻辑
    // 在这里实现Bi-phase mark解码逻辑的流水线
    // 解码逻辑将设置data_out和data_valid

endmodule