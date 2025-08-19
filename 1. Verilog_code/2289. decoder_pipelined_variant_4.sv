//SystemVerilog
module decoder_pipelined_axi (
    input wire clk,
    input wire resetn,
    
    // AXI-Stream Slave接口
    input wire [3:0] s_axis_tdata,
    input wire s_axis_tvalid,
    output wire s_axis_tready,
    
    // AXI-Stream Master接口
    output wire [15:0] m_axis_tdata,
    output wire m_axis_tvalid,
    input wire m_axis_tready
);

    reg [3:0] addr_reg;
    reg [15:0] decoded_reg;
    reg s_handshake_done;
    reg output_valid;
    
    // 输入握手处理
    assign s_axis_tready = m_axis_tready || !output_valid;
    
    // 输出有效信号
    assign m_axis_tvalid = output_valid;
    assign m_axis_tdata = decoded_reg;
    
    // 复位逻辑块
    always @(posedge clk or negedge resetn) begin
        if (!resetn) begin
            addr_reg <= 4'b0;
            decoded_reg <= 16'b0;
            s_handshake_done <= 1'b0;
            output_valid <= 1'b0;
        end
    end
    
    // 第一级流水线：接收并存储地址
    always @(posedge clk) begin
        if (resetn) begin
            if (s_axis_tvalid && s_axis_tready && !s_handshake_done) begin
                addr_reg <= s_axis_tdata;
                s_handshake_done <= 1'b1;
            end else if (s_handshake_done && (!output_valid || m_axis_tready)) begin
                s_handshake_done <= 1'b0;
            end
        end
    end
    
    // 第二级流水线：解码阶段
    always @(posedge clk) begin
        if (resetn) begin
            if (s_handshake_done && (!output_valid || m_axis_tready)) begin
                decoded_reg <= 1'b1 << addr_reg;
            end
        end
    end
    
    // 输出控制块
    always @(posedge clk) begin
        if (resetn) begin
            if (s_handshake_done && (!output_valid || m_axis_tready)) begin
                output_valid <= 1'b1;
            end else if (output_valid && m_axis_tready) begin
                output_valid <= 1'b0;
            end
        end
    end

endmodule