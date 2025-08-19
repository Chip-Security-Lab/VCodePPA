//SystemVerilog
module Comparator_AXIWrapper #(
    parameter C_S_AXI_DATA_WIDTH = 32,
    parameter C_S_AXI_ADDR_WIDTH = 4
)(
    // AXI-Lite接口信号
    input                              S_AXI_ACLK,
    input                              S_AXI_ARESETN,
    input  [C_S_AXI_ADDR_WIDTH-1:0]    S_AXI_AWADDR,
    input                              S_AXI_AWVALID,
    output reg                         S_AXI_AWREADY,
    input  [C_S_AXI_DATA_WIDTH-1:0]    S_AXI_WDATA,
    input                              S_AXI_WVALID,
    output reg                         S_AXI_WREADY,
    output reg [1:0]                   S_AXI_BRESP,
    output reg                         S_AXI_BVALID,
    input                              S_AXI_BREADY,
    input  [C_S_AXI_ADDR_WIDTH-1:0]    S_AXI_ARADDR,
    input                              S_AXI_ARVALID,
    output reg                         S_AXI_ARREADY,
    output reg [C_S_AXI_DATA_WIDTH-1:0] S_AXI_RDATA,
    output reg [1:0]                   S_AXI_RRESP,
    output reg                         S_AXI_RVALID,
    input                              S_AXI_RREADY,
    
    // 比较结果中断
    output reg                         irq
);
    // 寄存器定义
    reg [31:0] reg_comp_a;
    reg [31:0] reg_comp_b;
    reg        reg_ctrl;
    wire       comp_result;
    
    // 寄存器地址映射
    localparam ADDR_COMP_A = 4'h0;
    localparam ADDR_COMP_B = 4'h4;
    localparam ADDR_CTRL   = 4'h8;
    
    // 写入握手控制信号
    reg [C_S_AXI_ADDR_WIDTH-1:0] waddr;
    reg write_enable;
    
    //====================================================================
    // AXI写地址通道处理
    //====================================================================
    always @(posedge S_AXI_ACLK) begin
        if (!S_AXI_ARESETN) begin
            S_AXI_AWREADY <= 1'b0;
            waddr <= 0;
        end else begin
            if (S_AXI_AWVALID && !S_AXI_AWREADY) begin
                S_AXI_AWREADY <= 1'b1;
                waddr <= S_AXI_AWADDR;
            end else begin
                S_AXI_AWREADY <= 1'b0;
            end
        end
    end
    
    //====================================================================
    // AXI写数据通道处理
    //====================================================================
    always @(posedge S_AXI_ACLK) begin
        if (!S_AXI_ARESETN) begin
            S_AXI_WREADY <= 1'b0;
            write_enable <= 1'b0;
        end else begin
            if (S_AXI_WVALID && !S_AXI_WREADY) begin
                S_AXI_WREADY <= 1'b1;
                write_enable <= 1'b1;
            end else begin
                S_AXI_WREADY <= 1'b0;
                write_enable <= 1'b0;
            end
        end
    end
    
    //====================================================================
    // AXI写响应通道处理
    //====================================================================
    always @(posedge S_AXI_ACLK) begin
        if (!S_AXI_ARESETN) begin
            S_AXI_BVALID <= 1'b0;
            S_AXI_BRESP <= 2'b00;
        end else begin
            if (!S_AXI_BVALID && write_enable) begin
                S_AXI_BVALID <= 1'b1;
                S_AXI_BRESP <= 2'b00; // OKAY response
            end else if (S_AXI_BVALID && S_AXI_BREADY) begin
                S_AXI_BVALID <= 1'b0;
            end
        end
    end
    
    // 读取握手控制信号
    reg [C_S_AXI_ADDR_WIDTH-1:0] raddr;
    reg read_enable;
    
    //====================================================================
    // AXI读地址通道处理
    //====================================================================
    always @(posedge S_AXI_ACLK) begin
        if (!S_AXI_ARESETN) begin
            S_AXI_ARREADY <= 1'b0;
            raddr <= 0;
            read_enable <= 1'b0;
        end else begin
            read_enable <= 1'b0; // 默认禁用读取
            
            if (S_AXI_ARVALID && !S_AXI_ARREADY) begin
                S_AXI_ARREADY <= 1'b1;
                raddr <= S_AXI_ARADDR;
                read_enable <= 1'b1;
            end else begin
                S_AXI_ARREADY <= 1'b0;
            end
        end
    end
    
    //====================================================================
    // AXI读数据通道处理
    //====================================================================
    always @(posedge S_AXI_ACLK) begin
        if (!S_AXI_ARESETN) begin
            S_AXI_RVALID <= 1'b0;
            S_AXI_RDATA <= 0;
            S_AXI_RRESP <= 0;
        end else begin
            if (!S_AXI_RVALID && read_enable) begin
                S_AXI_RVALID <= 1'b1;
                S_AXI_RRESP <= 2'b00; // OKAY response
                
                case(raddr)
                    ADDR_COMP_A: S_AXI_RDATA <= reg_comp_a;
                    ADDR_COMP_B: S_AXI_RDATA <= reg_comp_b;
                    ADDR_CTRL:   S_AXI_RDATA <= {31'b0, reg_ctrl};
                    default:     S_AXI_RDATA <= 32'h00000000;
                endcase
            end else if (S_AXI_RVALID && S_AXI_RREADY) begin
                S_AXI_RVALID <= 1'b0;
            end
        end
    end
    
    //====================================================================
    // 寄存器写入处理
    //====================================================================
    always @(posedge S_AXI_ACLK) begin
        if (!S_AXI_ARESETN) begin
            reg_comp_a <= 32'h00000000;
            reg_comp_b <= 32'h00000000;
            reg_ctrl <= 1'b0;
        end else if (write_enable) begin
            case(waddr)
                ADDR_COMP_A: reg_comp_a <= S_AXI_WDATA;
                ADDR_COMP_B: reg_comp_b <= S_AXI_WDATA;
                ADDR_CTRL:   reg_ctrl <= S_AXI_WDATA[0];
            endcase
        end
    end
    
    //====================================================================
    // 比较器数据处理阶段1: 信号预处理
    //====================================================================
    wire [31:0] inverted_b;
    wire [31:0] diff;
    wire carry_in = 1'b1; // 取反加一
    wire [32:0] carries;  // 额外一位用于最终进位
    wire [31:0] p, g;     // 传播信号和生成信号
    
    // 取反操作代替减法的被减数
    assign inverted_b = ~reg_comp_b;
    
    // 定义传播信号和生成信号
    assign p = reg_comp_a ^ inverted_b;
    assign g = reg_comp_a & inverted_b;
    
    // 初始进位信号
    assign carries[0] = carry_in;
    
    //====================================================================
    // 比较器数据处理阶段2: 并行前缀计算 - 5级流水
    //====================================================================
    
    // 第一级前缀计算
    wire [31:0] p_level1, g_level1;
    genvar i;
    generate
        for (i = 0; i < 16; i = i + 1) begin: prefix_level1
            // 每两位为一组的前缀计算
            assign p_level1[2*i] = p[2*i];
            assign g_level1[2*i] = g[2*i];
            
            assign p_level1[2*i+1] = p[2*i+1] & p[2*i];
            assign g_level1[2*i+1] = g[2*i+1] | (p[2*i+1] & g[2*i]);
        end
    endgenerate
    
    // 第二级前缀计算
    wire [31:0] p_level2, g_level2;
    generate
        for (i = 0; i < 8; i = i + 1) begin: prefix_level2
            // 每四位为一组的前缀计算
            assign p_level2[4*i] = p_level1[4*i];
            assign g_level2[4*i] = g_level1[4*i];
            
            assign p_level2[4*i+1] = p_level1[4*i+1];
            assign g_level2[4*i+1] = g_level1[4*i+1];
            
            assign p_level2[4*i+2] = p_level1[4*i+2] & p_level1[4*i+1];
            assign g_level2[4*i+2] = g_level1[4*i+2] | (p_level1[4*i+2] & g_level1[4*i+1]);
            
            assign p_level2[4*i+3] = p_level1[4*i+3] & p_level1[4*i+2] & p_level1[4*i+1];
            assign g_level2[4*i+3] = g_level1[4*i+3] | (p_level1[4*i+3] & g_level1[4*i+2]) |
                                    (p_level1[4*i+3] & p_level1[4*i+2] & g_level1[4*i+1]);
        end
    endgenerate
    
    // 第三级前缀计算
    wire [31:0] p_level3, g_level3;
    generate
        for (i = 0; i < 4; i = i + 1) begin: prefix_level3
            // 每八位为一组
            for (genvar j = 0; j < 4; j = j + 1) begin
                assign p_level3[8*i+j] = p_level2[8*i+j];
                assign g_level3[8*i+j] = g_level2[8*i+j];
            end
            
            for (genvar j = 4; j < 8; j = j + 1) begin
                assign p_level3[8*i+j] = p_level2[8*i+j] & p_level2[8*i+3];
                assign g_level3[8*i+j] = g_level2[8*i+j] | (p_level2[8*i+j] & g_level2[8*i+3]);
            end
        end
    endgenerate
    
    // 第四级前缀计算
    wire [31:0] p_level4, g_level4;
    generate
        for (i = 0; i < 2; i = i + 1) begin: prefix_level4
            // 每十六位为一组
            for (genvar j = 0; j < 8; j = j + 1) begin
                assign p_level4[16*i+j] = p_level3[16*i+j];
                assign g_level4[16*i+j] = g_level3[16*i+j];
            end
            
            for (genvar j = 8; j < 16; j = j + 1) begin
                assign p_level4[16*i+j] = p_level3[16*i+j] & p_level3[16*i+7];
                assign g_level4[16*i+j] = g_level3[16*i+j] | (p_level3[16*i+j] & g_level3[16*i+7]);
            end
        end
    endgenerate
    
    // 第五级前缀计算 (最终级)
    wire [31:0] p_level5, g_level5;
    generate
        for (i = 0; i < 16; i = i + 1) begin
            assign p_level5[i] = p_level4[i];
            assign g_level5[i] = g_level4[i];
        end
        
        for (i = 16; i < 32; i = i + 1) begin
            assign p_level5[i] = p_level4[i] & p_level4[15];
            assign g_level5[i] = g_level4[i] | (p_level4[i] & g_level4[15]);
        end
    endgenerate
    
    //====================================================================
    // 比较器数据处理阶段3: 进位计算与结果生成
    //====================================================================
    
    // 计算所有位置的进位
    generate
        for (i = 1; i < 33; i = i + 1) begin
            if (i == 1) 
                assign carries[i] = g[0] | (p[0] & carries[0]);
            else
                assign carries[i] = g_level5[i-1] | (p_level5[i-1] & carries[0]);
        end
    endgenerate
    
    // 计算最终差值
    assign diff = p ^ {carries[31:0]};
    
    // 检查是否为零 (比较相等)
    assign comp_result = (diff == 32'h0) && (carries[32] == 1'b1);
    
    //====================================================================
    // 中断生成逻辑
    //====================================================================
    always @(posedge S_AXI_ACLK) begin
        if (!S_AXI_ARESETN) 
            irq <= 1'b0;
        else                
            irq <= reg_ctrl & comp_result;
    end
endmodule