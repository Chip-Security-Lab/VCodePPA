//SystemVerilog
module RD7 (
  // Clock and reset
  input  wire        aclk,
  input  wire        aresetn,
  
  // AXI-Stream Slave interface
  input  wire        s_axis_tvalid,
  output wire        s_axis_tready,
  
  // AXI-Stream Master interface
  output wire        m_axis_tvalid,
  output wire        m_axis_tdata,
  input  wire        m_axis_tready
);

  // 内部寄存器信号声明
  reg r1_ff, r2_ff;
  reg m_axis_tvalid_r;
  
  // 将原始复位信号与AXI接口关联
  wire rst_n_in = aresetn && s_axis_tvalid;
  wire rst_n_out;
  
  // 始终准备接收上游数据
  assign s_axis_tready = 1'b1;
  
  // 时序逻辑部分 - 仅在时钟边沿处理
  always @(posedge aclk or negedge aresetn) begin
    if (!aresetn) begin
      r1_ff <= 1'b0;
      r2_ff <= 1'b0;
      m_axis_tvalid_r <= 1'b0;
    end else begin
      if (s_axis_tvalid && s_axis_tready) begin
        r1_ff <= 1'b1;
        r2_ff <= r1_ff;
      end
      
      // 当数据处理完成后设置valid信号
      m_axis_tvalid_r <= r1_ff || r2_ff;
    end
  end
  
  // 组合逻辑部分 - 输出赋值
  assign rst_n_out = r2_ff;
  
  // AXI-Stream输出赋值
  assign m_axis_tvalid = m_axis_tvalid_r;
  assign m_axis_tdata = rst_n_out;
  
endmodule