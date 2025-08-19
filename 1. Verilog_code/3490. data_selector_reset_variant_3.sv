//SystemVerilog
module data_selector_reset #(
  parameter WIDTH = 8
)(
  input  logic                clk,
  input  logic                rst_n,
  input  logic [WIDTH-1:0]    data_a,
  input  logic [WIDTH-1:0]    data_b,
  input  logic [WIDTH-1:0]    data_c,
  input  logic [WIDTH-1:0]    data_d,
  input  logic [1:0]          select,
  output logic [WIDTH-1:0]    data_out
);

  // 重构的数据流路径 - 第一级：选择控制信号
  logic select_ge_one_stage1;
  logic [1:0] select_stage1;
  logic [WIDTH-1:0] data_a_stage1, data_b_stage1, data_c_stage1, data_d_stage1;
  
  // 第一级流水线寄存器
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      select_ge_one_stage1 <= 1'b0;
      select_stage1 <= 2'b00;
      data_a_stage1 <= {WIDTH{1'b0}};
      data_b_stage1 <= {WIDTH{1'b0}};
      data_c_stage1 <= {WIDTH{1'b0}};
      data_d_stage1 <= {WIDTH{1'b0}};
    end else begin
      select_ge_one_stage1 <= (select >= 2'b01);
      select_stage1 <= select;
      data_a_stage1 <= data_a;
      data_b_stage1 <= data_b;
      data_c_stage1 <= data_c;
      data_d_stage1 <= data_d;
    end
  end
  
  // 第二级：计算减法操作数
  logic [1:0] subtrahend_stage2, minuend_stage2;
  logic [1:0] select_stage2;
  logic [WIDTH-1:0] data_a_stage2, data_b_stage2, data_c_stage2, data_d_stage2;
  
  // 第二级流水线寄存器
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      subtrahend_stage2 <= 2'b00;
      minuend_stage2 <= 2'b00;
      select_stage2 <= 2'b00;
      data_a_stage2 <= {WIDTH{1'b0}};
      data_b_stage2 <= {WIDTH{1'b0}};
      data_c_stage2 <= {WIDTH{1'b0}};
      data_d_stage2 <= {WIDTH{1'b0}};
    end else begin
      subtrahend_stage2 <= select_ge_one_stage1 ? 2'b01 : select_stage1;
      minuend_stage2 <= select_ge_one_stage1 ? select_stage1 : 2'b01;
      select_stage2 <= select_stage1;
      data_a_stage2 <= data_a_stage1;
      data_b_stage2 <= data_b_stage1;
      data_c_stage2 <= data_c_stage1;
      data_d_stage2 <= data_d_stage1;
    end
  end
  
  // 第三级：计算减法结果
  logic [2:0] sub_result_stage3;
  logic [1:0] select_stage3;
  logic [WIDTH-1:0] mux_data_stage3;
  
  // 第三级流水线寄存器
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      sub_result_stage3 <= 3'b000;
      select_stage3 <= 2'b00;
      mux_data_stage3 <= {WIDTH{1'b0}};
    end else begin
      // 计算减法结果
      sub_result_stage3 <= {1'b0, minuend_stage2} - {1'b0, subtrahend_stage2};
      select_stage3 <= select_stage2;
      
      // 数据选择逻辑 - 合并到这一级以减少路径延迟
      case (select_stage2)
        2'b00: mux_data_stage3 <= data_a_stage2;
        2'b01: mux_data_stage3 <= data_b_stage2;
        2'b10: mux_data_stage3 <= data_c_stage2;
        2'b11: mux_data_stage3 <= data_d_stage2;
        default: mux_data_stage3 <= {WIDTH{1'b0}};
      endcase
    end
  end
  
  // 最终输出寄存器 - 合并第三级的结果
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      data_out <= {WIDTH{1'b0}};
    end else begin
      data_out <= mux_data_stage3;
    end
  end

endmodule