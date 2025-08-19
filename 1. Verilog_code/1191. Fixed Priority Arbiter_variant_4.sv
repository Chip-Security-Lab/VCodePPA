//SystemVerilog
module fixed_priority_arbiter #(
  parameter N = 4
)(
  input  wire        clk,
  input  wire        rst_n,
  input  wire [N-1:0] req,
  input  wire        valid_in,
  output reg  [N-1:0] grant,
  output reg         valid_out
);

  // ===== 数据流路径 Stage 1: 请求捕获 =====
  reg [N-1:0] stage1_req;
  reg         stage1_valid;

  // ===== 数据流路径 Stage 2: 优先级扫描前半部分 =====
  reg [N-1:0] stage2_req;        // 保存请求以供后续阶段使用
  reg [N-1:0] stage2_grant;      // 前半部分扫描结果
  reg         stage2_found;      // 前半部分是否找到授权
  reg         stage2_valid;

  // ===== 数据流路径 Stage 3: 优先级扫描后半部分 =====
  reg [N-1:0] stage3_grant;      // 最终授权结果
  reg         stage3_valid;

  // ============ 流水线级别1: 请求捕获 ============
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      stage1_req   <= {N{1'b0}};
      stage1_valid <= 1'b0;
    end
    else begin
      stage1_req   <= req;
      stage1_valid <= valid_in;
    end
  end
  
  // ============ 流水线级别2: 前半部分优先级处理 ============
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      stage2_req   <= {N{1'b0}};
      stage2_grant <= {N{1'b0}};
      stage2_found <= 1'b0;
      stage2_valid <= 1'b0;
    end
    else begin
      stage2_req   <= stage1_req;
      stage2_valid <= stage1_valid;
      stage2_grant <= {N{1'b0}};
      stage2_found <= 1'b0;
      
      // 扫描前半部分请求 (优先级从低到高索引)
      for (int i = 0; i < N/2; i = i + 1) begin
        if (stage1_req[i] && !stage2_found) begin
          stage2_grant[i] <= 1'b1;
          stage2_found    <= 1'b1;
        end
      end
    end
  end
  
  // ============ 流水线级别3: 后半部分优先级处理 ============
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      stage3_grant <= {N{1'b0}};
      stage3_valid <= 1'b0;
    end
    else begin
      stage3_valid <= stage2_valid;
      
      // 如果前半部分已找到授权，则直接使用该结果
      if (stage2_found) begin
        stage3_grant <= stage2_grant;
      end
      else begin
        stage3_grant <= {N{1'b0}};
        // 扫描后半部分请求
        for (int i = N/2; i < N; i = i + 1) begin
          if (stage2_req[i] && (stage3_grant == {N{1'b0}})) begin
            stage3_grant[i] <= 1'b1;
          end
        end
      end
    end
  end
  
  // ============ 流水线级别4: 输出阶段 ============
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      grant     <= {N{1'b0}};
      valid_out <= 1'b0;
    end
    else begin
      grant     <= stage3_grant;
      valid_out <= stage3_valid;
    end
  end

endmodule