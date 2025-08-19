//SystemVerilog
module one_hot_counter (
    input wire  clock,
    input wire  reset_n,
    
    // AXI-Stream Slave interface 
    input wire  s_axis_tvalid,
    output wire s_axis_tready,
    
    // AXI-Stream Master interface
    output wire        m_axis_tvalid,
    input wire         m_axis_tready,
    output wire [7:0]  m_axis_tdata,
    output wire        m_axis_tlast
);
    // 使用参数定义位宽，提高可扩展性
    localparam WIDTH = 8;
    
    // 内部寄存器
    reg [WIDTH-1:0] one_hot;
    reg data_valid;
    reg [2:0] counter;
    
    // 优化后的AXI-Stream握手逻辑
    wire transfer_ready;
    assign transfer_ready = s_axis_tvalid & m_axis_tready;
    assign s_axis_tready = m_axis_tready;
    assign m_axis_tvalid = data_valid & s_axis_tvalid;
    assign m_axis_tdata = one_hot;
    
    // 优化tlast信号生成，使用位比较而非相等比较
    assign m_axis_tlast = &counter;
    
    // 计数器逻辑优化
    always @(posedge clock or negedge reset_n) begin
        if (!reset_n)
            counter <= 3'b000;
        else if (m_axis_tvalid & m_axis_tready)
            counter <= counter + 1'b1;
    end
    
    // 优化的循环移位寄存器实现
    always @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            one_hot <= {{(WIDTH-1){1'b0}}, 1'b1}; // 使用参数化复位值
            data_valid <= 1'b0;
        end
        else begin
            // 将数据有效性检查移至此处，减少逻辑路径
            data_valid <= s_axis_tvalid;
            
            if (transfer_ready) begin
                // 使用位串联实现循环移位，可能提高某些FPGA架构上的性能
                one_hot <= (one_hot == {1'b1, {(WIDTH-1){1'b0}}}) ? {{(WIDTH-1){1'b0}}, 1'b1} : {one_hot[WIDTH-2:0], one_hot[WIDTH-1]};
            end
        end
    end
endmodule