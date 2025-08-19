//SystemVerilog
module reset_delay_monitor (
  input  wire clk,
  input  wire reset_n,
  output reg  reset_stuck_error
);
  // 定義狀態計數器和階段信號
  reg [15:0] delay_counter;
  reg        counter_threshold_reached;
  reg        reset_active_r;
  
  // 第一級：監控復位信號和計數器管理
  always @(posedge clk) begin
    // 同步復位信號到寄存器
    reset_active_r <= !reset_n;
    
    // 計數器控制邏輯 - 重置路徑
    if (reset_n) begin
      delay_counter <= 16'h0000;
    end 
    // 計數器進位邏輯 - 數據路徑
    else if (delay_counter != 16'hFFFF) begin
      delay_counter <= delay_counter + 16'h0001;
    end
  end
  
  // 第二級：閾值檢測路徑
  always @(posedge clk) begin
    // 預計算閾值檢測結果，將長路徑分割
    counter_threshold_reached <= (delay_counter == 16'hFFFE) && reset_active_r;
  end
  
  // 第三級：錯誤標誌生成路徑
  always @(posedge clk) begin
    // 基於閾值檢測結果設置錯誤標誌
    if (counter_threshold_reached) begin
      reset_stuck_error <= 1'b1;
    end
    else if (reset_n) begin
      reset_stuck_error <= 1'b0;
    end
  end
endmodule