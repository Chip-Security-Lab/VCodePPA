//SystemVerilog
module decoder_parity_axi_stream (
    input wire clk,
    input wire rst_n,
    
    // AXI-Stream 输入接口
    input wire [4:0] s_axis_tdata,  // [4]=parity, [3:0]=address
    input wire s_axis_tvalid,
    output wire s_axis_tready,
    
    // AXI-Stream 输出接口
    output wire [7:0] m_axis_tdata,  // 解码后的数据
    output wire m_axis_tvalid,
    output wire m_axis_tlast,
    input wire m_axis_tready
);

    // 流水线阶段寄存器
    reg [4:0] tdata_stage1;
    reg valid_stage1;
    reg parity_check_stage1;
    
    reg [3:0] addr_stage2;
    reg valid_stage2;
    reg parity_match_stage2;
    
    reg [7:0] decoded_data_stage3;
    reg valid_stage3;
    
    // 流水线控制信号 - 优化逻辑结构
    wire stage1_can_accept, stage2_can_accept, stage3_can_accept;
    wire stage1_fire, stage2_fire, stage3_fire;
    
    // 优化校验位计算 - 使用XOR运算符更高效地计算奇偶校验
    wire calculated_parity = s_axis_tdata[0] ^ s_axis_tdata[1] ^ s_axis_tdata[2] ^ s_axis_tdata[3];
    wire parity_match = (calculated_parity == s_axis_tdata[4]);
    
    // 优化流水线控制逻辑 - 改进信号传播路径
    assign stage1_can_accept = !valid_stage1 || stage2_can_accept;
    assign stage2_can_accept = !valid_stage2 || stage3_can_accept;
    assign stage3_can_accept = !valid_stage3 || m_axis_tready;
    
    assign stage1_fire = s_axis_tvalid && stage1_can_accept;
    assign stage2_fire = valid_stage1 && stage2_can_accept;
    assign stage3_fire = valid_stage2 && stage3_can_accept;
    
    // 优化握手信号逻辑
    assign s_axis_tready = stage1_can_accept;
    assign m_axis_tvalid = valid_stage3;
    assign m_axis_tlast = 1'b1;  // 每次传输都是单个数据
    assign m_axis_tdata = decoded_data_stage3;
    
    // 阶段1: 输入捕获和校验计算 - 合并逻辑判断
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            tdata_stage1 <= 5'h0;
            valid_stage1 <= 1'b0;
            parity_check_stage1 <= 1'b0;
        end else if (stage1_fire) begin
            tdata_stage1 <= s_axis_tdata;
            valid_stage1 <= 1'b1;
            parity_check_stage1 <= parity_match;
        end else if (stage2_fire) begin
            valid_stage1 <= 1'b0;
        end
    end
    
    // 阶段2: 解码操作 - 简化逻辑路径
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            addr_stage2 <= 4'h0;
            valid_stage2 <= 1'b0;
            parity_match_stage2 <= 1'b0;
        end else if (stage2_fire) begin
            addr_stage2 <= tdata_stage1[3:0];
            valid_stage2 <= 1'b1;
            parity_match_stage2 <= parity_check_stage1;
        end else if (stage3_fire) begin
            valid_stage2 <= 1'b0;
        end
    end
    
    // 阶段3: 输出准备 - 优化译码逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            decoded_data_stage3 <= 8'h0;
            valid_stage3 <= 1'b0;
        end else if (stage3_fire) begin
            // 优化移位操作，利用特定情况下硬件可能提供的快速移位路径
            decoded_data_stage3 <= parity_match_stage2 ? (8'h1 << addr_stage2) : 8'h0;
            valid_stage3 <= 1'b1;
        end else if (valid_stage3 && m_axis_tready) begin
            valid_stage3 <= 1'b0;
        end
    end

endmodule